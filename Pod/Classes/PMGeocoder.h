//
// PMGeocoder.h
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "PMPlacemark.h"

typedef enum {
	PMGeocoderZeroResultsError = 1,
	PMGeocoderOverQueryLimitError,
	PMGeocoderRequestDeniedError,
	PMGeocoderInvalidRequestError,
    PMGeocoderJSONParsingError
} PMGecoderError;


typedef void (^PMGeocoderCompletionHandler)(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error);

@interface PMGeocoder : NSOperation

+ (PMGeocoder*)reverseGeocode:(CLLocationCoordinate2D)coordinate completion:(PMGeocoderCompletionHandler)block;
+ (PMGeocoder*)reverseGeocode:(CLLocationCoordinate2D)coordinate useLocale:(NSLocale *)locale completion:(PMGeocoderCompletionHandler)block;

- (PMGeocoder*)initWithCoordinate:(CLLocationCoordinate2D)coordinate forLocale:(NSLocale *)locale completion:(PMGeocoderCompletionHandler)block;

- (void)start;
- (void)cancel;

@end