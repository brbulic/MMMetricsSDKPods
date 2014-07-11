#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

/** 
 * Create NS_ENUM macro if it does not exist on the targeted version of iOS or OS X.
 *
 * @see http://nshipster.com/ns_enum-ns_options/
 **/
#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

extern NSString *const kPMReachabilityChangedNotification;

typedef NS_ENUM(NSInteger, PMNetworkStatus) {
    // Apple NetworkStatus Compatible Names.
    NotReachable = 0,
    ReachableViaWiFi = 2,
    ReachableViaWWAN = 1
};

@class PMReachabilityWrapper;

typedef void (^PMNetworkReachable)(PMReachabilityWrapper * reachability);
typedef void (^PMNetworkUnreachable)(PMReachabilityWrapper * reachability);

@interface PMReachabilityWrapper : NSObject

@property (nonatomic, copy) PMNetworkReachable    reachableBlock;
@property (nonatomic, copy) PMNetworkUnreachable  unreachableBlock;


@property (nonatomic, assign) BOOL reachableOnWWAN;

+(PMReachabilityWrapper*)reachabilityWithHostname:(NSString*)hostname;
+(PMReachabilityWrapper*)reachabilityForInternetConnection;
+(PMReachabilityWrapper*)reachabilityWithAddress:(const struct sockaddr_in*)hostAddress;
+(PMReachabilityWrapper*)reachabilityForLocalWiFi;

-(PMReachabilityWrapper *)initWithReachabilityRef:(SCNetworkReachabilityRef)ref;

-(BOOL)startNotifier;
-(void)stopNotifier;

-(BOOL)isReachable;
-(BOOL)isReachableViaWWAN;
-(BOOL)isReachableViaWiFi;

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
-(BOOL)isConnectionRequired; // Identical DDG variant.
-(BOOL)connectionRequired; // Apple's routine.
// Dynamic, on demand connection?
-(BOOL)isConnectionOnDemand;
// Is user intervention required?
-(BOOL)isInterventionRequired;

-(PMNetworkStatus)currentReachabilityStatus;
-(SCNetworkReachabilityFlags)reachabilityFlags;
-(NSString*)currentReachabilityString;
-(NSString*)currentReachabilityFlags;

@end
