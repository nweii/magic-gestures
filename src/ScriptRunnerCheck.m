// Verifies that a configured executable runs directly, uses its own directory,
// and reports completion without blocking the caller.

#import <Foundation/Foundation.h>
#import "ScriptRunner.h"

int main(void) {
    @autoreleasepool {
        NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:
                               [[NSUUID UUID] UUIDString]];
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
        NSString *script = [directory stringByAppendingPathComponent:@"write-result"];
        [@"#!/bin/sh\nprintf launched > result.txt\n" writeToFile:script
                                                      atomically:YES
                                                        encoding:NSUTF8StringEncoding
                                                           error:NULL];
        [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @0700}
                                        ofItemAtPath:script
                                               error:NULL];

        dispatch_semaphore_t finished = dispatch_semaphore_create(0);
        __block int status = -1;
        NSError *error = nil;
        BOOL launched = [ScriptRunner launchScriptAtPath:script
                                                   error:&error
                                      terminationHandler:^(int terminationStatus) {
            status = terminationStatus;
            dispatch_semaphore_signal(finished);
        }];
        if (!launched) {
            fprintf(stderr, "FAIL  script did not launch: %s\n",
                    [[[error localizedDescription] ?: @"unknown error" description] UTF8String]);
            return 1;
        }
        if (dispatch_semaphore_wait(finished,
                dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC)) != 0) {
            fprintf(stderr, "FAIL  script did not finish within three seconds\n");
            return 1;
        }

        NSString *resultPath = [directory stringByAppendingPathComponent:@"result.txt"];
        NSString *result = [NSString stringWithContentsOfFile:resultPath
                                                     encoding:NSUTF8StringEncoding
                                                        error:NULL];
        if (status != 0 || ![result isEqualToString:@"launched"]) {
            fprintf(stderr, "FAIL  script status=%d result=%s\n",
                    status, [[result ?: @"(missing)" description] UTF8String]);
            return 1;
        }
        printf("script runner: all checks passed\n");
        return 0;
    }
}
