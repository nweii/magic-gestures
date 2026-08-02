// Checks deterministic serialization, privacy rejection, bounded capture, ordering, and bundle output.

#import <Foundation/Foundation.h>
#import "TraceRecorder.h"

static int failures = 0;

static void require(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "FAIL  %s\n", [message UTF8String]);
        failures++;
    }
}

int main(void) {
    @autoreleasepool {
        NSDictionary *event = @{@"schema": @1, @"session": @"test", @"step": @"s",
            @"segment": @1, @"record_seq": @2, @"t_ns": @3, @"source": @"guide",
            @"event": @"test", @"device": [NSNull null], @"data": @{@"z": @1, @"a": @2}};
        NSString *problem = nil;
        NSData *first = MGTraceDeterministicJSONLine(event, &problem);
        NSData *second = MGTraceDeterministicJSONLine(event, &problem);
        require(first != nil && [first isEqualToData:second],
                @"identical events did not serialize deterministically");
        NSString *line = [[[NSString alloc] initWithData:first encoding:NSUTF8StringEncoding] autorelease];
        require([line hasSuffix:@"\n"] && [line rangeOfString:@"\"a\":2"].location <
                [line rangeOfString:@"\"z\":1"].location,
                @"serialized trace is not stable sorted NDJSON");

        for (NSString *privateKey in @[@"application_name", @"configured_command",
                                        @"keycode", @"url_value", @"script_path",
                                        @"clipboard", @"cursor_position", @"device_id"]) {
            NSMutableDictionary *leak = [event mutableCopy];
            [leak setObject:@{privateKey: @"private"} forKey:@"data"];
            require(MGTraceDeterministicJSONLine(leak, &problem) == nil && problem != nil,
                    [privateKey stringByAppendingString:@" reached serialization"]);
            [leak release];
        }

        NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:
            [NSString stringWithFormat:@"MGTraceCheck-%@", [[NSUUID UUID] UUIDString]]];
        require(MGTraceStart(root, &problem), @"trace session did not start");
        MGTraceBeginStep(@"normal-r1", @"two-finger-click", YES, @"Click once");
        MGTraceContact contacts[] = {{1, 4, 0.3, 0.7, 1.2, 8.2, 6.1, 0.0}};
        for (int i = 0; i < 12000; i++)
            MGTraceRecordMouseFrame((void *)0x1, 1.0 + i, i, contacts, 1);
        MGTraceRecordDispatch(@"Two-Finger Click", @"global", @"built-in", @"suppressed-for-trace");
        MGTraceMarkStep(@"success");
        MGTraceStop();

        NSDictionary *labels = [NSJSONSerialization JSONObjectWithData:
            [NSData dataWithContentsOfFile:[root stringByAppendingPathComponent:@"labels.json"]]
            options:0 error:nil];
        require(labels != nil && [[labels objectForKey:@"dropped_events"] unsignedIntegerValue] > 0,
                @"capture did not enforce its pending-event bound");
        NSString *events = [NSString stringWithContentsOfFile:
            [root stringByAppendingPathComponent:@"events.ndjson"]
            encoding:NSUTF8StringEncoding error:nil];
        require([events rangeOfString:@"private"].location == NSNotFound,
                @"rejected private value appeared in capture");
        unsigned long long previous = 0;
        for (NSString *row in [events componentsSeparatedByString:@"\n"]) {
            if ([row length] == 0) continue;
            NSDictionary *decoded = [NSJSONSerialization JSONObjectWithData:
                [row dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            unsigned long long sequence = [[decoded objectForKey:@"record_seq"] unsignedLongLongValue];
            require(sequence > previous, @"record sequence did not preserve enqueue order");
            previous = sequence;
        }
        require(previous > 0, @"capture wrote no events");

        if (failures == 0) {
            printf("trace recorder: all checks passed\n");
            return 0;
        }
        fprintf(stderr, "trace recorder: %d failure(s)\n", failures);
        return 1;
    }
}
