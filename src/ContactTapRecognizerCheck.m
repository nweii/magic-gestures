// Checks exact-count tap timing, movement rejection, and full-lift reset behavior.

#import <Foundation/Foundation.h>

#import "ContactTapRecognizer.h"

static void require(BOOL condition, NSString *message) {
    if (!condition) {
        NSLog(@"%@", message);
        exit(1);
    }
}

static BOOL recognize(double start, double target, double end,
                      int peakCount, float endX, float endY) {
    MGContactTapRecognizer recognizer;
    MGContactTapRecognizerInitialize(&recognizer, 5);
    MGContactTapRecognizerUpdate(&recognizer, 1, 0.50, 0.50, YES, start);
    MGContactTapRecognizerUpdate(&recognizer, peakCount, 0.50, 0.50, YES, target);
    MGContactTapRecognizerUpdate(&recognizer, peakCount, endX, endY, YES, end - 0.01);
    return MGContactTapRecognizerUpdate(&recognizer, 0, 0, 0, YES, end);
}

int main(void) {
    @autoreleasepool {
        require(recognize(1.000, 1.025, 1.120, 5, 0.505, 0.505),
                @"intentional five-contact tap was rejected");
        require(!recognize(2.000, 2.005, 2.015, 5, 0.50, 0.50),
                @"phantom contact sequence became a tap");
        require(!recognize(3.000, 3.080, 3.140, 5, 0.50, 0.50),
                @"slow finger placement became a tap");
        require(!recognize(4.000, 4.020, 4.120, 6, 0.50, 0.50),
                @"six contacts became a five-contact tap");
        require(!recognize(5.000, 5.020, 5.120, 5, 0.54, 0.50),
                @"moving contacts became a tap");
        require(!recognize(6.000, 6.020, 6.400, 5, 0.50, 0.50),
                @"long hold became a tap");

        MGContactTapRecognizer recognizer;
        MGContactTapRecognizerInitialize(&recognizer, 5);
        MGContactTapRecognizerUpdate(&recognizer, 6, 0.50, 0.50, YES, 7.000);
        require(!MGContactTapRecognizerUpdate(&recognizer, 0, 0, 0, YES, 7.100),
                @"rejected sequence fired on lift");
        MGContactTapRecognizerUpdate(&recognizer, 5, 0.50, 0.50, YES, 8.000);
        require(MGContactTapRecognizerUpdate(&recognizer, 0, 0, 0, YES, 8.100),
                @"full lift did not reset the recognizer");

        MGContactTapRecognizerUpdate(&recognizer, 5, 0.50, 0.50, NO, 9.000);
        require(!MGContactTapRecognizerUpdate(&recognizer, 0, 0, 0, YES, 9.100),
                @"ineligible broad contacts became a tap");

        NSLog(@"contact tap recognizer: all checks passed");
    }
    return 0;
}
