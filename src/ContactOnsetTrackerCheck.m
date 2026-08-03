// Exercises contact-onset tracking with deliberate, resting, and reused contacts.
// These checks keep simultaneous-contact eligibility independent of recognizer callback timing.

#import <Foundation/Foundation.h>

#import "ContactOnsetTracker.h"

static void require(BOOL condition, NSString *message) {
    if (!condition) {
        NSLog(@"%@", message);
        exit(1);
    }
}

int main(void) {
    @autoreleasepool {
        MGContactOnsetTracker tracker = {0};
        int first[] = {11};
        int pair[] = {11, 12};
        MGContactOnsetTrackerObserve(&tracker, first, 1, 10.000);
        MGContactOnsetTrackerObserve(&tracker, pair, 2, 10.085);
        require(MGContactOnsetTrackerContactsArrivedWithin(&tracker, pair, 2, 0.120),
                @"deliberate contacts arriving within the onset window were rejected");

        MGContactOnsetTrackerObserve(&tracker, NULL, 0, 10.200);
        int resting[] = {21};
        int restingPair[] = {21, 22};
        MGContactOnsetTrackerObserve(&tracker, resting, 1, 20.000);
        MGContactOnsetTrackerObserve(&tracker, restingPair, 2, 20.196);
        require(!MGContactOnsetTrackerContactsArrivedWithin(&tracker, restingPair, 2, 0.120),
                @"resting contact and later touch were accepted as a tap");

        MGContactOnsetTrackerObserve(&tracker, NULL, 0, 20.300);
        int reusedFirst[] = {21};
        int reusedTriplet[] = {21, 22, 23};
        MGContactOnsetTrackerObserve(&tracker, reusedFirst, 1, 30.000);
        MGContactOnsetTrackerObserve(&tracker, reusedTriplet, 3, 30.040);
        require(MGContactOnsetTrackerContactsArrivedWithin(&tracker, reusedTriplet, 3, 0.120),
                @"a reused identifier retained a prior contact lifetime");

        int missing[] = {21, 24};
        require(!MGContactOnsetTrackerContactsArrivedWithin(&tracker, missing, 2, 0.120),
                @"a contact without a recorded onset was accepted");

        NSLog(@"contact onset tracker: all checks passed");
    }
    return 0;
}
