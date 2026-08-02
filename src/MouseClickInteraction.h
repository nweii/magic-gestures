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
} MGMouseClickInteraction;

void MGMouseClickInteractionInitialize(MGMouseClickInteraction *interaction);
int MGMouseClickInteractionObserveContacts(MGMouseClickInteraction *interaction,
                                           int eligibleContactCount,
                                           double timestamp);
void MGMouseClickInteractionBegin(MGMouseClickInteraction *interaction,
                                  double timestamp);
void MGMouseClickInteractionMarkHandled(MGMouseClickInteraction *interaction);
void MGMouseClickInteractionRecordDrag(MGMouseClickInteraction *interaction,
                                       int deltaX, int deltaY);
int MGMouseClickInteractionFinish(MGMouseClickInteraction *interaction);
