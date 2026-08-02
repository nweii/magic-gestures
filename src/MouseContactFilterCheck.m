// Checks resting-edge rejection against measured ordinary and intentional Magic Mouse clicks.

#import <Foundation/Foundation.h>

#import "MouseContactFilter.h"

static void require(BOOL condition, NSString *message) {
    if (!condition) {
        NSLog(@"%@", message);
        exit(1);
    }
}

int main(void) {
    @autoreleasepool {
        require(MGMagicMouseContactShouldBeExcluded(0.9620, 0.6574, 0.8750,
                                                    6.5800),
                @"measured right-edge resting contact was retained");
        require(MGMagicMouseContactShouldBeExcluded(0.0380, 0.6574, 0.8750,
                                                    6.5800),
                @"equivalent left-edge resting contact was retained");
        require(MGMagicMouseContactShouldBeExcluded(0.9448, 0.1200, 0.3750,
                                                    4.3900),
                @"measured rear palm contact was retained");
        require(MGMagicMouseContactShouldBeExcluded(0.5000, 0.2000, 0.7500,
                                                    6.0000),
                @"rear palm passed the relaxed two-contact click threshold");
        require(!MGMagicMouseContactShouldBeExcluded(0.5000, 0.2000, 1.5000,
                                                     8.1000),
                @"substantial fingertip near the rear was rejected");
        require(!MGMagicMouseContactShouldBeExcluded(0.7901, 0.7643, 2.2500,
                                                     8.4900),
                @"measured intentional fingertip was rejected");
        require(!MGMagicMouseContactShouldBeExcluded(0.9500, 0.7000, 1.5000,
                                                     8.1000),
                @"substantial fingertip near the edge was rejected");
        require(!MGMagicMouseContactShouldBeExcluded(0.5000, 0.7000, 0.5000,
                                                     5.0000),
                @"small central fingertip was rejected");

        float intentionalXs[] = {0.3484, 0.7901};
        float intentionalYs[] = {0.7058, 0.7643};
        require(MGMagicMouseContactsFormClickCluster(
                    intentionalXs, intentionalYs, 2),
                @"measured intentional two-finger click was not a cluster");
        float restingXs[] = {0.2908, 0.9620};
        float restingYs[] = {0.6963, 0.6574};
        require(!MGMagicMouseContactsFormClickCluster(restingXs, restingYs, 2),
                @"isolated resting edge contact joined the click cluster");
        float threeXs[] = {0.20, 0.48, 0.76};
        float threeYs[] = {0.70, 0.72, 0.69};
        require(MGMagicMouseContactsFormClickCluster(threeXs, threeYs, 3),
                @"connected three-finger click was rejected by total span");
        threeXs[2] = 0.99;
        require(!MGMagicMouseContactsFormClickCluster(threeXs, threeYs, 3),
                @"isolated third contact joined a click cluster");

        NSLog(@"mouse contact filter: all checks passed");
    }
    return 0;
}
