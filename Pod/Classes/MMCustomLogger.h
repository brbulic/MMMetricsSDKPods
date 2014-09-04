//
//  MMCustomLogger.h
//  Pods
//
//  Created by Bruno Bulić on 04/09/14.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MMCustomLoggerVerbosity) {
    Error = 0,
    Info = 1,
    Debug = 2,
    Verbose = 3,
};

@interface MMCustomLogger : NSObject

@property (nonatomic, assign) MMCustomLoggerVerbosity loggerVerbosity;

+ (instancetype)sharedInstance;

- (void)logInfo:(NSString *)format, ...;
- (void)logError:(NSString *)format, ...;
- (void)logVerbose:(NSString *)format, ...;
- (void)logDebug:(NSString *)format, ...;

@end


#define MMLogDebug(...) [[MMCustomLogger sharedInstance] logDebug:__VA_ARGS__]
#define MMLogError(...) [[MMCustomLogger sharedInstance] logError:__VA_ARGS__]
#define MMLogVerbose(...) [[MMCustomLogger sharedInstance] logVerbose:__VA_ARGS__]
#define MMLogInfo(...) [[MMCustomLogger sharedInstance] logInfo:__VA_ARGS__]