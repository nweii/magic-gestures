// Launches configured executable scripts without passing their contents through
// a shell, and reports process completion asynchronously.

#import <Foundation/Foundation.h>

typedef void (^MGScriptTerminationHandler)(int terminationStatus);

@interface ScriptRunner : NSObject

+ (BOOL)launchScriptAtPath:(NSString *)path
                     error:(NSError **)outError
        terminationHandler:(MGScriptTerminationHandler)handler;

@end
