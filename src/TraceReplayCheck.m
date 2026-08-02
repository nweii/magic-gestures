// Replays synthetic trace-derived cases through click correlation, contact filtering, and sequence ownership.

#import <Foundation/Foundation.h>
#import "GestureSequence.h"
#import "MouseClickInteraction.h"
#import "MouseContactFilter.h"

static void require(BOOL condition, NSString *message) {
    if (!condition) { fprintf(stderr, "FAIL  %s\n", [message UTF8String]); exit(1); }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        require(argc == 2, @"fixture path is required");
        NSDictionary *fixture = [NSJSONSerialization JSONObjectWithData:
            [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]]
            options:0 error:nil];
        require([[fixture objectForKey:@"schema"] isEqual:@1], @"unsupported replay fixture");
        for (NSDictionary *testCase in [fixture objectForKey:@"cases"]) {
            MGMouseClickInteraction click;
            MGMouseClickInteractionInitialize(&click);
            MGGestureSequence sequence;
            MGGestureSequenceInitialize(&sequence);
            for (NSDictionary *event in [testCase objectForKey:@"events"]) {
                NSString *type = [event objectForKey:@"type"];
                if ([type isEqualToString:@"mouse_begin"])
                    MGMouseClickInteractionBegin(&click, [[event objectForKey:@"t"] doubleValue]);
                else if ([type isEqualToString:@"contacts"])
                    MGMouseClickInteractionObserveContacts(&click, [[event objectForKey:@"count"] intValue],
                                                            [[event objectForKey:@"t"] doubleValue]);
                else if ([type isEqualToString:@"drag"])
                    MGMouseClickInteractionRecordDrag(&click);
                else if ([type isEqualToString:@"mouse_finish"])
                    require(MGMouseClickInteractionFinish(&click) == [[event objectForKey:@"expect"] intValue],
                            [testCase objectForKey:@"name"]);
                else if ([type isEqualToString:@"filter"]) {
                    NSString *decision = MGMagicMouseContactDecisionName(
                        MGMagicMouseContactDecisionForGeometry([[event objectForKey:@"x"] floatValue],
                            [[event objectForKey:@"y"] floatValue], [[event objectForKey:@"size"] floatValue],
                            [[event objectForKey:@"minor"] floatValue]));
                    require([decision isEqualToString:[event objectForKey:@"expect"]], [testCase objectForKey:@"name"]);
                } else if ([type isEqualToString:@"claim"]) {
                    BOOL result = MGGestureSequenceTryClaim(&sequence, [[event objectForKey:@"owner"] unsignedIntegerValue]);
                    require(result == [[event objectForKey:@"expect"] boolValue], [testCase objectForKey:@"name"]);
                } else if ([type isEqualToString:@"lift"])
                    MGGestureSequenceFinishFrame(&sequence, 0);
            }
        }
        printf("trace replay: all checks passed\n");
    }
    return 0;
}
