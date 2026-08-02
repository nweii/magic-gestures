// Checks that Magic Mouse physical clicks correlate touch frames arriving after mouse-down.

#import <Foundation/Foundation.h>
#import "MouseClickInteraction.h"

static int failures = 0;

static void require(BOOL condition, NSString *message) {
    if (!condition) {
        fprintf(stderr, "FAIL  %s\n", [message UTF8String]);
        failures++;
    }
}

int main(void) {
    @autoreleasepool {
        MGMouseClickInteraction interaction;
        MGMouseClickInteractionInitialize(&interaction);
        MGMouseClickInteractionBegin(&interaction, 10.0);
        MGMouseClickInteractionObserveContacts(&interaction, 2, 10.06);
        require(MGMouseClickInteractionFinish(&interaction) == 2,
                @"a valid touch frame arriving after mouse-down did not complete the two-finger click");

        MGMouseClickInteractionObserveContacts(&interaction, 0, 14.9);
        MGMouseClickInteractionBegin(&interaction, 15.0);
        require(MGMouseClickInteractionFinish(&interaction) == 0,
                @"mouse-up dispatched before a valid touch frame arrived");
        require(MGMouseClickInteractionObserveContacts(&interaction, 2, 15.06) == 2,
                @"a valid touch frame arriving just after mouse-up did not complete the click");

        MGMouseClickInteractionObserveContacts(&interaction, 1, 20.0);
        MGMouseClickInteractionBegin(&interaction, 20.0);
        require(MGMouseClickInteractionFinish(&interaction) == 0,
                @"an ordinary one-contact click became a multi-finger click");

        MGMouseClickInteractionBegin(&interaction, 30.0);
        MGMouseClickInteractionObserveContacts(&interaction, 2, 30.11);
        require(MGMouseClickInteractionFinish(&interaction) == 0,
                @"a contact arriving outside the hardware grace window completed a click");

        MGMouseClickInteractionBegin(&interaction, 40.0);
        MGMouseClickInteractionObserveContacts(&interaction, 2, 40.04);
        MGMouseClickInteractionRecordDrag(&interaction);
        require(MGMouseClickInteractionFinish(&interaction) == 0,
                @"a physical drag completed a click action");

        MGMouseClickInteractionBegin(&interaction, 50.0);
        MGMouseClickInteractionObserveContacts(&interaction, 2, 50.04);
        MGMouseClickInteractionMarkHandled(&interaction);
        require(MGMouseClickInteractionFinish(&interaction) == 0,
                @"an immediately handled click dispatched again on mouse-up");

        if (failures == 0) {
            printf("mouse click interaction: all checks passed\n");
            return 0;
        }
        fprintf(stderr, "mouse click interaction: %d failure(s)\n", failures);
        return 1;
    }
}
