// Implements shared contact-quality, click-cancellation, claiming, and lifecycle rules for trackpad taps.

#import "TrackpadInteraction.h"

static const float kTrackpadBroadContactMajorAxis = 10.5;

void MGTrackpadInteractionInitialize(MGTrackpadInteraction *interaction) {
    interaction->broadContact = NO;
    interaction->physicalClick = NO;
    interaction->claimed = NO;
    interaction->previousContactCount = 0;
    interaction->sequenceStartTime = -1;
    interaction->latestArrivalTime = -1;
}

void MGTrackpadInteractionObserveContacts(MGTrackpadInteraction *interaction,
                                          const float *majorAxes,
                                          int contactCount,
                                          double timestamp) {
    if (interaction->previousContactCount == 0 && contactCount > 0) {
        MGTrackpadInteractionInitialize(interaction);
        interaction->sequenceStartTime = timestamp;
        interaction->latestArrivalTime = timestamp;
    } else if (contactCount > interaction->previousContactCount) {
        interaction->latestArrivalTime = timestamp;
    }

    for (int i = 0; i < contactCount; i++) {
        if (majorAxes[i] > kTrackpadBroadContactMajorAxis)
            interaction->broadContact = YES;
    }
}

void MGTrackpadInteractionRecordPhysicalClick(MGTrackpadInteraction *interaction) {
    interaction->physicalClick = YES;
}

BOOL MGTrackpadInteractionContactsArrivedWithin(const MGTrackpadInteraction *interaction,
                                                double maximumInterval) {
    return interaction->sequenceStartTime >= 0 &&
           interaction->latestArrivalTime - interaction->sequenceStartTime <= maximumInterval;
}

BOOL MGTrackpadInteractionClaimTap(MGTrackpadInteraction *interaction) {
    if (interaction->broadContact || interaction->physicalClick || interaction->claimed)
        return NO;
    interaction->claimed = YES;
    return YES;
}

void MGTrackpadInteractionFinishFrame(MGTrackpadInteraction *interaction, int contactCount) {
    interaction->previousContactCount = contactCount;
    if (contactCount == 0)
        MGTrackpadInteractionInitialize(interaction);
}
