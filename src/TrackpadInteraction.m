// Implements shared contact-quality, physical-click, drag, claiming, and lifecycle rules for trackpad gestures.

#import "TrackpadInteraction.h"

static const float kTrackpadBroadContactMajorAxis = 10.5;
static const float kTrackpadThumbMaximumY = 0.35;

BOOL MGTrackpadInteractionContactsAreEligible(const float *majorAxes,
                                              int contactCount) {
    for (int i = 0; i < contactCount; i++) {
        if (majorAxes[i] > kTrackpadBroadContactMajorAxis)
            return NO;
    }
    return YES;
}

BOOL MGTrackpadInteractionFiveFingerContactsAreEligible(const float *majorAxes,
                                                        const float *ys,
                                                        int contactCount) {
    int broadContactCount = 0;
    for (int i = 0; i < contactCount; i++) {
        if (majorAxes[i] > kTrackpadBroadContactMajorAxis) {
            broadContactCount++;
            if (broadContactCount > 1 || ys[i] > kTrackpadThumbMaximumY)
                return NO;
        }
    }
    return YES;
}

void MGTrackpadInteractionInitialize(MGTrackpadInteraction *interaction) {
    interaction->broadContact = NO;
    interaction->physicalClick = NO;
    interaction->physicalDrag = NO;
    MGGestureSequenceInitialize(&interaction->sequence);
    interaction->previousContactCount = 0;
    interaction->previousActiveContactCount = 0;
    interaction->currentContactCount = 0;
    interaction->maximumContactCount = 0;
    interaction->pendingClickContactCount = 0;
    interaction->sequenceStartTime = -1;
    interaction->latestArrivalTime = -1;
}

void MGTrackpadInteractionObserveContacts(MGTrackpadInteraction *interaction,
                                          const MGTrackpadContact *contacts,
                                          int contactCount,
                                          double timestamp) {
    if (interaction->previousActiveContactCount == 0 && contactCount > 0) {
        MGTrackpadInteractionInitialize(interaction);
        interaction->sequenceStartTime = timestamp;
        interaction->latestArrivalTime = timestamp;
    } else if (contactCount > interaction->previousContactCount) {
        interaction->latestArrivalTime = timestamp;
    }

    if (contactCount > interaction->maximumContactCount)
        interaction->maximumContactCount = contactCount;

    for (int i = 0; i < contactCount; i++) {
        if (contacts[i].majorAxis > kTrackpadBroadContactMajorAxis)
            interaction->broadContact = YES;
    }
    interaction->previousContactCount = contactCount;
    interaction->currentContactCount = contactCount;
}

BOOL MGTrackpadInteractionBeginPhysicalClick(MGTrackpadInteraction *interaction,
                                             double pressure,
                                             NSUInteger owner) {
    if (interaction->currentContactCount <= 0 || pressure <= 0 || interaction->broadContact ||
        !MGGestureSequenceTryClaim(&interaction->sequence, owner))
        return NO;

    interaction->physicalClick = YES;
    interaction->physicalDrag = NO;
    interaction->pendingClickContactCount = MAX(interaction->currentContactCount,
                                                 interaction->maximumContactCount);
    return YES;
}

BOOL MGTrackpadInteractionHasPhysicalClick(const MGTrackpadInteraction *interaction) {
    return interaction->physicalClick;
}

BOOL MGTrackpadInteractionShouldPreservePrimaryClick(const MGTrackpadInteraction *interaction,
                                                     BOOL threeFingerBindingAvailable,
                                                     BOOL fourFingerBindingAvailable) {
    return interaction->physicalClick &&
        ((interaction->pendingClickContactCount == 3 && threeFingerBindingAvailable) ||
         (interaction->pendingClickContactCount == 4 && fourFingerBindingAvailable));
}

void MGTrackpadInteractionRecordPhysicalDrag(MGTrackpadInteraction *interaction) {
    if (interaction->physicalClick)
        interaction->physicalDrag = YES;
}

int MGTrackpadInteractionFinishPhysicalClick(MGTrackpadInteraction *interaction) {
    int contactCount = interaction->physicalClick && !interaction->physicalDrag
        ? interaction->pendingClickContactCount
        : 0;
    BOOL contactsAlreadyLifted = interaction->previousActiveContactCount == 0;
    interaction->physicalClick = NO;
    interaction->physicalDrag = NO;
    interaction->maximumContactCount = interaction->currentContactCount;
    interaction->pendingClickContactCount = 0;
    if (contactsAlreadyLifted)
        MGTrackpadInteractionInitialize(interaction);
    return contactCount;
}

BOOL MGTrackpadInteractionContactsArrivedWithin(const MGTrackpadInteraction *interaction,
                                                double maximumInterval) {
    return interaction->sequenceStartTime >= 0 &&
           interaction->latestArrivalTime - interaction->sequenceStartTime <= maximumInterval;
}

BOOL MGTrackpadInteractionClaimGesture(MGTrackpadInteraction *interaction,
                                       NSUInteger owner) {
    return MGGestureSequenceTryClaim(&interaction->sequence, owner);
}

BOOL MGTrackpadInteractionClaimTap(MGTrackpadInteraction *interaction,
                                   NSUInteger owner) {
    if (interaction->broadContact || interaction->physicalClick)
        return NO;
    return MGTrackpadInteractionClaimGesture(interaction, owner);
}

void MGTrackpadInteractionFinishFrame(MGTrackpadInteraction *interaction,
                                      int activeContactCount) {
    interaction->previousActiveContactCount = activeContactCount;
    if (activeContactCount == 0 && interaction->pendingClickContactCount == 0)
        MGTrackpadInteractionInitialize(interaction);
}
