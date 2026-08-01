// Checks trackpad tap classification and arbitration against intentional and palm-contact sequences.

#import <Foundation/Foundation.h>

#import "TrackpadInteraction.h"

static void require(BOOL condition, NSString *message) {
    if (!condition) {
        NSLog(@"%@", message);
        exit(1);
    }
}

int main(void) {
    @autoreleasepool {
        MGTrackpadInteraction interaction;
        MGTrackpadInteractionInitialize(&interaction);

        float fingertip[] = {8.95};
        MGTrackpadInteractionObserveContacts(&interaction, fingertip, 1, 1.000);
        MGTrackpadInteractionFinishFrame(&interaction, 1);
        float fingertips[] = {8.95, 8.72, 8.51};
        MGTrackpadInteractionObserveContacts(&interaction, fingertips, 3, 1.008);
        require(MGTrackpadInteractionContactsArrivedWithin(&interaction, 0.05),
                @"intentional three-finger arrival was rejected");
        require(MGTrackpadInteractionClaimTap(&interaction), @"intentional tap could not claim sequence");
        require(!MGTrackpadInteractionClaimTap(&interaction), @"two gestures claimed one sequence");
        MGTrackpadInteractionFinishFrame(&interaction, 0);

        float palms[] = {17.62, 18.27, 14.68};
        MGTrackpadInteractionObserveContacts(&interaction, palms, 3, 2.000);
        require(!MGTrackpadInteractionClaimTap(&interaction), @"broad palm contacts claimed a tap");
        MGTrackpadInteractionFinishFrame(&interaction, 0);

        MGTrackpadInteractionObserveContacts(&interaction, fingertip, 1, 3.000);
        MGTrackpadInteractionFinishFrame(&interaction, 1);
        MGTrackpadInteractionObserveContacts(&interaction, fingertips, 2, 3.100);
        MGTrackpadInteractionRecordPhysicalClick(&interaction);
        require(!MGTrackpadInteractionClaimTap(&interaction), @"physical click also claimed a tap gesture");
        MGTrackpadInteractionFinishFrame(&interaction, 0);

        MGTrackpadInteractionObserveContacts(&interaction, fingertips, 3, 4.000);
        require(MGTrackpadInteractionClaimTap(&interaction), @"full lift did not reset interaction");

        NSLog(@"trackpad interaction: all checks passed");
    }
    return 0;
}
