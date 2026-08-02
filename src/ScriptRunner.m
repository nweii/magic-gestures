// Launches configured executable scripts without passing their contents through
// a shell, and retains each process until its asynchronous completion.

#import "ScriptRunner.h"

static NSString *const MGScriptErrorDomain = @"MagicGesturesScript";

static NSError *scriptError(NSInteger code, NSString *description) {
    return [NSError errorWithDomain:MGScriptErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

static NSMutableSet *activeScriptTasks(void) {
    static NSMutableSet *tasks = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tasks = [[NSMutableSet alloc] init];
    });
    return tasks;
}

@implementation ScriptRunner

+ (BOOL)launchScriptAtPath:(NSString *)path
                     error:(NSError **)outError
        terminationHandler:(MGScriptTerminationHandler)handler {
    NSString *resolved = [[path stringByExpandingTildeInPath] stringByStandardizingPath];
    NSError *problem = nil;
    NSDictionary *attributes = [[NSFileManager defaultManager]
                                attributesOfItemAtPath:resolved error:NULL];
    if (![resolved isAbsolutePath])
        problem = scriptError(1, @"Script must use an absolute path or begin with ~");
    else if (attributes == nil)
        problem = scriptError(2, @"Script file does not exist");
    else if (![[attributes objectForKey:NSFileType] isEqualToString:NSFileTypeRegular])
        problem = scriptError(3, @"Script path is not a regular file");
    else if (![[NSFileManager defaultManager] isExecutableFileAtPath:resolved])
        problem = scriptError(4, @"Script file is not executable");

    if (problem != nil) {
        if (outError != NULL)
            *outError = problem;
        return NO;
    }

    NSTask *task = [[NSTask alloc] init];
    [task setExecutableURL:[NSURL fileURLWithPath:resolved]];
    [task setCurrentDirectoryURL:[NSURL fileURLWithPath:[resolved stringByDeletingLastPathComponent]
                                             isDirectory:YES]];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    [task setTerminationHandler:^(NSTask *finishedTask) {
        int status = [finishedTask terminationStatus];
        if (status != 0)
            NSLog(@"Script \"%@\" exited with status %d", resolved, status);
        if (handler != nil)
            handler(status);
        @synchronized (activeScriptTasks()) {
            [activeScriptTasks() removeObject:finishedTask];
        }
        [finishedTask setTerminationHandler:nil];
    }];

    @synchronized (activeScriptTasks()) {
        [activeScriptTasks() addObject:task];
    }
    BOOL launched = [task launchAndReturnError:&problem];
    if (!launched) {
        @synchronized (activeScriptTasks()) {
            [activeScriptTasks() removeObject:task];
        }
        [task setTerminationHandler:nil];
        if (outError != NULL)
            *outError = problem;
    }
    [task release];
    return launched;
}

@end
