//
// SVPlacemark.h
// SVGeocoder
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface PMPlacemark : NSObject

- (id)initWithDictionary:(NSDictionary*)dictionary;

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *formattedAddress;
@property (nonatomic, strong, readonly) NSString *subThoroughfare;
@property (nonatomic, strong, readonly) NSString *thoroughfare;
@property (nonatomic, strong, readonly) NSString *subLocality;
@property (nonatomic, strong, readonly) NSString *locality;
@property (nonatomic, strong, readonly) NSString *subAdministrativeArea;
@property (nonatomic, strong, readonly) NSString *administrativeArea;
@property (nonatomic, strong, readonly) NSString *administrativeAreaCode;
@property (nonatomic, strong, readonly) NSString *postalCode;
@property (nonatomic, strong, readonly) NSString *country;
@property (nonatomic, strong, readonly) NSString *ISOcountryCode;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong, readonly) CLLocation *location;

@end
