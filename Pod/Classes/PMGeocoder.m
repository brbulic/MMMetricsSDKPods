//
// PMGeocoder.m
//
// Created by Sam Vermette on 07.02.11.
// Copyright 2011 samvermette.com. All rights reserved.
//
// https://github.com/samvermette/SVGeocoder
// http://code.google.com/apis/maps/documentation/geocoding/
//

#import "PMGeocoder.h" 

#define kPMGeocoderTimeoutInterval 20

enum {
    PMGeocoderStateReady = 0,
    PMGeocoderStateExecuting,
    PMGeocoderStateFinished
};

typedef NSUInteger PMGeocoderState;


@interface NSString (URLEncoding)
- (NSString*)encodedURLParameterString;
@end


@interface PMGeocoder ()

@property (nonatomic, strong) NSMutableURLRequest *operationRequest;
@property (nonatomic, strong) NSMutableData *operationData;
@property (nonatomic, strong) NSURLConnection *operationConnection;
@property (nonatomic, strong) NSHTTPURLResponse *operationURLResponse;

@property (nonatomic, copy) PMGeocoderCompletionHandler operationCompletionBlock;
@property (nonatomic, assign, getter = state, setter = setState:) PMGeocoderState state;
@property (nonatomic, strong) NSString *requestPath;
@property (nonatomic, strong) NSTimer *timeoutTimer; // see http://stackoverflow.com/questions/2736967

- (PMGeocoder*)initWithParameters:(NSMutableDictionary*)parameters withLocale:(NSLocale *)locale completion:(PMGeocoderCompletionHandler)block;

- (void)addParametersToRequest:(NSMutableDictionary*)parameters;
- (void)finish;

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)callCompletionBlockWithResponse:(id)response error:(NSError *)error;

@end

@implementation PMGeocoder

@synthesize state = _state;

#pragma mark -

- (void)dealloc {
    [_operationConnection cancel];
    [super dealloc];
}

#pragma mark - Convenience Initializers

+ (PMGeocoder *)reverseGeocode:(CLLocationCoordinate2D)coordinate completion:(PMGeocoderCompletionHandler)block {
    NSLocale * currentLocale = [NSLocale currentLocale];
    
    PMGeocoder *geocoder = [[self alloc] initWithCoordinate:coordinate forLocale:currentLocale completion:block];
    [geocoder start];
    return geocoder;
}

+ (PMGeocoder *)reverseGeocode:(CLLocationCoordinate2D)coordinate useLocale:(NSLocale *)locale completion:(PMGeocoderCompletionHandler)block {
    PMGeocoder *geocoder = [[self alloc] initWithCoordinate:coordinate forLocale:locale completion:block];
    [geocoder start];
    return geocoder;
}

#pragma mark - Public Initializers

- (PMGeocoder*)initWithCoordinate:(CLLocationCoordinate2D)coordinate forLocale:(NSLocale *)locale completion:(PMGeocoderCompletionHandler)block {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                       [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude], @"latlng", nil];
    
    return [self initWithParameters:parameters withLocale:locale completion:block];
}

#pragma mark - Private Utility Methods

- (PMGeocoder*)initWithParameters:(NSMutableDictionary*)parameters withLocale:(NSLocale *)locale completion:(PMGeocoderCompletionHandler)block {
    self = [super init];
    self.operationCompletionBlock = block;
    self.operationRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://maps.googleapis.com/maps/api/geocode/json"]];
    [self.operationRequest setTimeoutInterval:kPMGeocoderTimeoutInterval];

    [parameters setValue:@"true" forKey:@"sensor"];
    [parameters setValue:[locale objectForKey:NSLocaleLanguageCode] forKey:@"language"];
    [self addParametersToRequest:parameters];
        
    self.state = PMGeocoderStateReady;
    
    return self;
}

- (void)addParametersToRequest:(NSMutableDictionary*)parameters {
    
    NSMutableArray *paramStringsArray = [NSMutableArray arrayWithCapacity:[[parameters allKeys] count]];
    
    for(NSString *key in [parameters allKeys]) {
        NSObject *paramValue = [parameters valueForKey:key];
		if ([paramValue isKindOfClass:[NSString class]]) {
			[paramStringsArray addObject:[NSString stringWithFormat:@"%@=%@", key, [(NSString *)paramValue encodedURLParameterString]]];			
		} else {
			[paramStringsArray addObject:[NSString stringWithFormat:@"%@=%@", key, paramValue]];
		}
    }
    
    NSString *paramsString = [paramStringsArray componentsJoinedByString:@"&"];
    NSString *baseAddress = self.operationRequest.URL.absoluteString;
    baseAddress = [baseAddress stringByAppendingFormat:@"?%@", paramsString];
    [self.operationRequest setURL:[NSURL URLWithString:baseAddress]];
}

- (void)setTimeoutTimer:(NSTimer *)newTimer {
    
    if(_timeoutTimer)
        [_timeoutTimer invalidate], _timeoutTimer = nil;
    
    if(newTimer)
        _timeoutTimer = newTimer;
}

#pragma mark - NSOperation methods

- (void)start {
        
    if(self.isCancelled) {
        [self finish];
        return;
    }
    
    if(![NSThread isMainThread]) { // NSOperationQueue calls start from a bg thread (through GCD), but NSURLConnection already does that by itself
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    self.state = PMGeocoderStateExecuting;
    [self didChangeValueForKey:@"isExecuting"];
    
    self.operationData = [[NSMutableData alloc] init];
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kPMGeocoderTimeoutInterval target:self selector:@selector(requestTimeout) userInfo:nil repeats:NO];
    
    self.operationConnection = [[NSURLConnection alloc] initWithRequest:self.operationRequest delegate:self startImmediately:NO];
    [self.operationConnection start];
    
#if !(defined SVHTTPREQUEST_DISABLE_LOGGING)
    NSLog(@"[%@] %@", self.operationRequest.HTTPMethod, self.operationRequest.URL.absoluteString);
#endif
}

- (void)finish {
    [self.operationConnection cancel];
    _operationConnection = nil;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.state = PMGeocoderStateFinished;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)cancel {
    if([self isFinished])
        return;
    
    [super cancel];
    [self callCompletionBlockWithResponse:nil error:nil];
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isFinished {
    return self.state == PMGeocoderStateFinished;
}

- (BOOL)isExecuting {
    return self.state == PMGeocoderStateExecuting;
}

- (PMGeocoderState)state {
    @synchronized(self) {
        return _state;
    }
}

- (void)setState:(PMGeocoderState)newState {
    @synchronized(self) {
        [self willChangeValueForKey:@"state"];
        _state = newState;
        [self didChangeValueForKey:@"state"];
    }
}


#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)requestTimeout {
    NSURL *failingURL = self.operationRequest.URL;
    
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"The operation timed out.",
                              NSURLErrorFailingURLErrorKey: failingURL,
                              NSURLErrorFailingURLStringErrorKey: failingURL.absoluteString};
    
    NSError *timeoutError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:userInfo];
    [self connection:nil didFailWithError:timeoutError];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.operationURLResponse = (NSHTTPURLResponse*)response;
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.operationData appendData:data];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSMutableArray *placemarks = nil;
    NSError *error = nil;
    
    if ([[_operationURLResponse MIMEType] isEqualToString:@"application/json"]) {
        if(self.operationData && self.operationData.length > 0) {
            id response = [NSData dataWithData:self.operationData];
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:&error];
            NSArray *results = jsonObject[@"results"];
            NSString *status = [jsonObject valueForKey:@"status"];
            
            if(results)
                placemarks = [NSMutableArray arrayWithCapacity:results.count];
            
            if(results.count > 0) {
                [results enumerateObjectsUsingBlock:^(NSDictionary *result, NSUInteger idx, BOOL *stop) {
                    PMPlacemark *placemark = [[PMPlacemark alloc] initWithDictionary:result];
                    [placemarks addObject:placemark];
                }];
            }
            else {
                if ([status isEqualToString:@"ZERO_RESULTS"]) {
                    NSDictionary *userinfo = @{NSLocalizedDescriptionKey: @"Zero results returned"};
                    error = [NSError errorWithDomain:@"PMGeocoderErrorDomain" code:PMGeocoderZeroResultsError userInfo:userinfo];
                }
                
                else if ([status isEqualToString:@"OVER_QUERY_LIMIT"]) {
                    NSDictionary *userinfo = @{NSLocalizedDescriptionKey: @"Currently rate limited. Too many queries in a short time. (Over Quota)"};
                    error = [NSError errorWithDomain:@"PMGeocoderErrorDomain" code:PMGeocoderOverQueryLimitError userInfo:userinfo];
                }
                
                else if ([status isEqualToString:@"REQUEST_DENIED"]) {
                    NSDictionary *userinfo = @{NSLocalizedDescriptionKey: @"Request was denied. Did you remember to add the \"sensor\" parameter?"};
                    error = [NSError errorWithDomain:@"PMGeocoderErrorDomain" code:PMGeocoderRequestDeniedError userInfo:userinfo];
                }
                
                else if ([status isEqualToString:@"INVALID_REQUEST"]) {
                    NSDictionary *userinfo = @{NSLocalizedDescriptionKey: @"The request was invalid. Was the \"address\" or \"latlng\" missing?"};
                    error = [NSError errorWithDomain:@"PMGeocoderErrorDomain" code:PMGeocoderInvalidRequestError userInfo:userinfo];
                }
            }
        }
    }
    
    [self callCompletionBlockWithResponse:placemarks error:error];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self callCompletionBlockWithResponse:nil error:error];
}

- (void)callCompletionBlockWithResponse:(id)response error:(NSError *)error {
    self.timeoutTimer = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *serverError = error;
        
        if(!serverError && self.operationURLResponse.statusCode == 500) {
            serverError = [NSError errorWithDomain:NSURLErrorDomain
                                              code:NSURLErrorBadServerResponse
                                          userInfo:@{NSLocalizedDescriptionKey: @"Bad Server Response.",
                                                    NSURLErrorFailingURLErrorKey: self.operationRequest.URL,
                                                    NSURLErrorFailingURLStringErrorKey: self.operationRequest.URL.absoluteString}];
        }
        
        if(self.operationCompletionBlock && !self.isCancelled)
            self.operationCompletionBlock([response copy], self.operationURLResponse, serverError);
        
        [self finish];
    });
}


@end


#pragma mark -

@implementation NSString (URLEncoding)

- (NSString*)encodedURLParameterString {
    NSString *result = (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                          (__bridge CFStringRef)self,
                                                                          NULL,
                                                                          CFSTR(":/=,!$&'()*+;[]@#?|"),
                                                                          kCFStringEncodingUTF8));
	return result;
}

@end
