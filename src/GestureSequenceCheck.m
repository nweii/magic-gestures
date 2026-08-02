// Checks that competing gestures cannot claim the same touch sequence and that lift permits the next gesture.

#import <Foundation/Foundation.h>

#import "GestureSequence.h"

static void require(BOOL condition, NSString *message) {
    if (!condition) {
        NSLog(@"%@", message);
        exit(1);
    }
}

int main(void) {
    @autoreleasepool {
        MGGestureSequence sequence;
        MGGestureSequenceInitialize(&sequence);

        require(MGGestureSequenceTryClaim(&sequence, 1), @"first gesture could not claim sequence");
        require(MGGestureSequenceTryClaim(&sequence, 1), @"owning gesture could not repeat");
        require(!MGGestureSequenceTryClaim(&sequence, 2), @"competing gesture claimed the same sequence");

        MGGestureSequenceFinishFrame(&sequence, 1);
        require(!MGGestureSequenceTryClaim(&sequence, 2),
                @"a filtered contact manufactured a full lift");

        MGGestureSequenceFinishFrame(&sequence, 0);
        require(MGGestureSequenceTryClaim(&sequence, 2),
                @"raw full lift did not release sequence ownership");

        MGGestureSequenceInitialize(&sequence);
        require(MGGestureSequenceTryClaim(&sequence, 2), @"full lift did not release sequence ownership");

        NSLog(@"gesture sequence: all checks passed");
    }
    return 0;
}
