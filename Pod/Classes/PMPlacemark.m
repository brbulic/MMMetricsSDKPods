//
// SVPlacemark.m
// SVGeocoder
//
#import "PMPlacemark.h"

@interface PMPlacemark ()

@property (nonatomic, strong, readwrite) NSString *formattedAddress;
@property (nonatomic, strong, readwrite) NSString *subThoroughfare;
@property (nonatomic, strong, readwrite) NSString *thoroughfare;
@property (nonatomic, strong, readwrite) NSString *subLocality;
@property (nonatomic, strong, readwrite) NSString *locality;
@property (nonatomic, strong, readwrite) NSString *subAdministrativeArea;
@property (nonatomic, strong, readwrite) NSString *administrativeArea;
@property (nonatomic, strong, readwrite) NSString *administrativeAreaCode;
@property (nonatomic, strong, readwrite) NSString *postalCode;
@property (nonatomic, strong, readwrite) NSString *country;
@property (nonatomic, strong, readwrite) NSString *ISOcountryCode;

@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong, readwrite) CLLocation *location;

@end


@implementation PMPlacemark

@synthesize formattedAddress, subThoroughfare, thoroughfare, subLocality, locality, subAdministrativeArea, administrativeArea, administrativeAreaCode, postalCode, country, ISOcountryCode, coordinate, location;

- (id)initWithDictionary:(NSDictionary *)result {
    
    if(self = [super init]) {
        self.formattedAddress = result[@"formatted_address"];
        
        NSArray *addressComponents = result[@"address_components"];
        
        [addressComponents enumerateObjectsUsingBlock:^(NSDictionary *component, NSUInteger idx, BOOL *stopAddress) {
            NSArray *types = component[@"types"];
            
            if([types containsObject:@"street_number"])
                self.subThoroughfare = component[@"long_name"];
            
            if([types containsObject:@"route"])
                self.thoroughfare = component[@"long_name"];
            
            if([types containsObject:@"administrative_area_level_3"] || [types containsObject:@"sublocality"] || [types containsObject:@"neighborhood"])
                self.subLocality = component[@"long_name"];
            
            if([types containsObject:@"locality"])
                self.locality = component[@"long_name"];
            
            if([types containsObject:@"administrative_area_level_2"])
                self.subAdministrativeArea = component[@"long_name"];
            
            if([types containsObject:@"administrative_area_level_1"]) {
                self.administrativeArea = component[@"long_name"];
                self.administrativeAreaCode = component[@"short_name"];
            }
            
            if([types containsObject:@"country"]) {
                self.country = component[@"long_name"];
                self.ISOcountryCode = component[@"short_name"];
            }
            
            if([types containsObject:@"postal_code"])
                self.postalCode = component[@"long_name"];
            
        }];
        
        NSDictionary *locationDict = result[@"geometry"][@"location"];
        
        CLLocationDegrees lat = [locationDict[@"lat"] doubleValue];
        CLLocationDegrees lng = [locationDict[@"lng"] doubleValue];
        self.coordinate = CLLocationCoordinate2DMake(lat, lng);
        self.location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];

    }
    
    return self;
}

- (NSString *)name {
    if(self.subThoroughfare && self.thoroughfare)
        return [NSString stringWithFormat:@"%@ %@", self.subThoroughfare, self.thoroughfare];
    else if(self.thoroughfare)
        return self.thoroughfare;
    else if(self.subLocality)
        return self.subLocality;
    else if(self.locality)
        return [NSString stringWithFormat:@"%@, %@", self.locality, self.administrativeAreaCode];
    else if(self.administrativeArea)
        return self.administrativeArea;
    else if(self.country)
        return self.country;
    return nil;
}

- (NSString*)description {
    NSDictionary *dict = @{@"formattedAddress": formattedAddress,
                          @"subThoroughfare": subThoroughfare?subThoroughfare:[NSNull null],
                          @"thoroughfare": thoroughfare?thoroughfare:[NSNull null],
                          @"subLocality": subLocality?subLocality:[NSNull null],
                          @"locality": locality?locality:[NSNull null],
                          @"subAdministrativeArea": subAdministrativeArea?subAdministrativeArea:[NSNull null],
                          @"administrativeArea": administrativeArea?administrativeArea:[NSNull null],
                          @"postalCode": postalCode?postalCode:[NSNull null],
                          @"country": country?country:[NSNull null],
                          @"ISOcountryCode": ISOcountryCode?ISOcountryCode:[NSNull null],
                          @"coordinate": [NSString stringWithFormat:@"%f, %f", self.coordinate.latitude, self.coordinate.longitude]};
    
	return [dict description];
}

@end
