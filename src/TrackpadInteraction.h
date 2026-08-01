// Classifies a trackpad contact sequence and arbitrates among tap recognizers that could claim it.

#import <Foundation/Foundation.h>

typedef struct {
    BOOL broadContact;
    BOOL physicalClick;
    BOOL claimed;
    int previousContactCount;
    double sequenceStartTime;
    double latestArrivalTime;
} MGTrackpadInteraction;

void MGTrackpadInteractionInitialize(MGTrackpadInteraction *interaction);
void MGTrackpadInteractionObserveContacts(MGTrackpadInteraction *interaction,
                                          const float *majorAxes,
                                          int contactCount,
                                          double timestamp);
void MGTrackpadInteractionRecordPhysicalClick(MGTrackpadInteraction *interaction);
BOOL MGTrackpadInteractionContactsArrivedWithin(const MGTrackpadInteraction *interaction,
                                                double maximumInterval);
BOOL MGTrackpadInteractionClaimTap(MGTrackpadInteraction *interaction);
void MGTrackpadInteractionFinishFrame(MGTrackpadInteraction *interaction, int contactCount);
