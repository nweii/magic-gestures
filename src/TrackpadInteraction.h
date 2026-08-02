// Classifies a trackpad contact sequence and arbitrates among recognizers that could claim it.

#import <Foundation/Foundation.h>
#import "GestureSequence.h"

typedef struct {
    int identifier;
    float x;
    float y;
    float majorAxis;
} MGTrackpadContact;

typedef struct {
    BOOL broadContact;
    BOOL physicalClick;
    BOOL physicalDrag;
    MGGestureSequence sequence;
    int previousContactCount;
    int previousActiveContactCount;
    int currentContactCount;
    int maximumContactCount;
    int pendingClickContactCount;
    double sequenceStartTime;
    double latestArrivalTime;
} MGTrackpadInteraction;

void MGTrackpadInteractionInitialize(MGTrackpadInteraction *interaction);
void MGTrackpadInteractionObserveContacts(MGTrackpadInteraction *interaction,
                                          const MGTrackpadContact *contacts,
                                          int contactCount,
                                          double timestamp);
BOOL MGTrackpadInteractionContactsAreEligible(const float *majorAxes,
                                              int contactCount);
BOOL MGTrackpadInteractionFiveFingerContactsAreEligible(const float *majorAxes,
                                                        const float *ys,
                                                        int contactCount);
BOOL MGTrackpadInteractionBeginPhysicalClick(MGTrackpadInteraction *interaction,
                                             double pressure,
                                             NSUInteger owner);
BOOL MGTrackpadInteractionHasPhysicalClick(const MGTrackpadInteraction *interaction);
BOOL MGTrackpadInteractionShouldPreservePrimaryClick(const MGTrackpadInteraction *interaction,
                                                     BOOL threeFingerBindingAvailable,
                                                     BOOL fourFingerBindingAvailable);
void MGTrackpadInteractionRecordPhysicalDrag(MGTrackpadInteraction *interaction);
int MGTrackpadInteractionFinishPhysicalClick(MGTrackpadInteraction *interaction);
BOOL MGTrackpadInteractionContactsArrivedWithin(const MGTrackpadInteraction *interaction,
                                                double maximumInterval);
BOOL MGTrackpadInteractionClaimGesture(MGTrackpadInteraction *interaction,
                                       NSUInteger owner);
BOOL MGTrackpadInteractionClaimTap(MGTrackpadInteraction *interaction,
                                   NSUInteger owner);
void MGTrackpadInteractionFinishFrame(MGTrackpadInteraction *interaction,
                                      int activeContactCount);
