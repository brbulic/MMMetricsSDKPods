//
//  MMCustomLogger.m
//  Pods
//
//  Created by Bruno Bulić on 04/09/14.
//
//

#import "MMCustomLogger.h"

@implementation MMCustomLogger

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static MMCustomLogger * instance;
    dispatch_once(&onceToken, ^{
        instance = [self new];
        [instance setLoggerVerbosity:Info];
    });
    
    return instance;
}

- (NSString *)verbosityFromEnum: (MMCustomLoggerVerbosity)verbosity {
    switch (verbosity) {
        case Info:
            return @"INFO";
        case Error:
            return @"ERROR";
        case Debug:
            return @"DEBUG";
        case Verbose:
            return @"VERBOSE";
        default:
            return @"HACKER YOU ARE";
    }
    
    return nil;
}

- (void)internalLogWithVerbosity:(MMCustomLoggerVerbosity)verbosity withFormat:(NSString *)format arguments:(va_list)list {
    if (verbosity > self.loggerVerbosity) {
        return;
    }
        
    NSString * e = [[NSString alloc] initWithFormat:format arguments:list];

    NSLog(@":: [%@] -> %@", [self verbosityFromEnum:verbosity], e);
}

#pragma mark - Publics

- (void)logInfo:(NSString *)format, ... {
    va_list list;
    va_start(list, format);
    [self internalLogWithVerbosity:Info withFormat:format arguments:list];
    va_end(list);
}

- (void)logError:(NSString *)format, ... {
    va_list list;
    va_start(list, format);
    [self internalLogWithVerbosity:Error withFormat:format arguments:list];
    va_end(list);
}

- (void)logVerbose:(NSString *)format, ... {
    va_list list;
    va_start(list, format);
    [self internalLogWithVerbosity:Verbose withFormat:format arguments:list];
    va_end(list);
}

- (void)logDebug:(NSString *)format, ... {
    va_list list;
    va_start(list, format);
    [self internalLogWithVerbosity:Debug withFormat:format arguments:list];
    va_end(list);
}

@end