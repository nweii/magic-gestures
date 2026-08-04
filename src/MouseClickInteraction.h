// Declares the Magic Mouse physical-click lifetime used to bridge CG mouse events and later touch frames.

#import <Foundation/Foundation.h>
#import <os/lock.h>

typedef struct {
    os_unfair_lock lock;
    BOOL active;
    BOOL handled;
    BOOL dragged;
    BOOL released;
    int currentContactCount;
    int peakContactCount;
    int cumulativeDeltaX;
    int cumulativeDeltaY;
    double mouseDownTime;
    uint64_t rawFrameGeneration;
    uint64_t eligibleFrameGeneration;
    int rawContactCount;
} MGMouseClickInteraction;

typedef enum {
    MGMouseClickEligibilityNoRawContacts = 0,
    MGMouseClickEligibilityFilterPending = 1,
    MGMouseClickEligibilityFilteredOut = 2,
    MGMouseClickEligibilityAvailable = 3,
} MGMouseClickEligibilityStage;

typedef struct {
    MGMouseClickEligibilityStage stage;
    int rawContactCount;
    int eligibleContactCount;
} MGMouseClickEligibilitySnapshot;

void MGMouseClickInteractionInitialize(MGMouseClickInteraction *interaction);
void MGMouseClickInteractionObserveRawContacts(MGMouseClickInteraction *interaction,
                                               int rawContactCount);
int MGMouseClickInteractionObserveContacts(MGMouseClickInteraction *interaction,
                                           int eligibleContactCount,
                                           double timestamp);
MGMouseClickEligibilitySnapshot MGMouseClickInteractionEligibilitySnapshot(
    MGMouseClickInteraction *interaction);
void MGMouseClickInteractionBegin(MGMouseClickInteraction *interaction,
                                  double timestamp);
void MGMouseClickInteractionMarkHandled(MGMouseClickInteraction *interaction);
void MGMouseClickInteractionRecordDrag(MGMouseClickInteraction *interaction,
                                       int deltaX, int deltaY);
int MGMouseClickInteractionFinish(MGMouseClickInteraction *interaction);
