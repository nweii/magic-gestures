// Tracks one Magic Mouse physical click across the CG event and touch-frame streams.

#import "MouseClickInteraction.h"

static const double kMouseClickContactArrivalGrace = 0.10;

static void finishInteractionWhileLocked(MGMouseClickInteraction *interaction) {
    interaction->active = NO;
    interaction->handled = NO;
    interaction->dragged = NO;
    interaction->released = NO;
    interaction->peakContactCount = interaction->currentContactCount;
    interaction->mouseDownTime = -1;
}

void MGMouseClickInteractionInitialize(MGMouseClickInteraction *interaction) {
    interaction->lock = OS_UNFAIR_LOCK_INIT;
    os_unfair_lock_lock(&interaction->lock);
    interaction->active = NO;
    interaction->handled = NO;
    interaction->dragged = NO;
    interaction->released = NO;
    interaction->currentContactCount = 0;
    interaction->peakContactCount = 0;
    interaction->mouseDownTime = -1;
    os_unfair_lock_unlock(&interaction->lock);
}

int MGMouseClickInteractionObserveContacts(MGMouseClickInteraction *interaction,
                                           int eligibleContactCount,
                                           double timestamp) {
    os_unfair_lock_lock(&interaction->lock);
    interaction->currentContactCount = eligibleContactCount;
    BOOL withinGrace = timestamp >= interaction->mouseDownTime &&
        timestamp - interaction->mouseDownTime <= kMouseClickContactArrivalGrace;
    if (interaction->active && withinGrace &&
        (eligibleContactCount == 2 || eligibleContactCount == 3)) {
        interaction->peakContactCount = MAX(interaction->peakContactCount,
                                             eligibleContactCount);
    }
    if (interaction->active && interaction->released && !withinGrace) {
        finishInteractionWhileLocked(interaction);
        os_unfair_lock_unlock(&interaction->lock);
        return 0;
    }
    if (interaction->active && interaction->released && !interaction->handled &&
        !interaction->dragged &&
        (interaction->peakContactCount == 2 || interaction->peakContactCount == 3)) {
        int contactCount = interaction->peakContactCount;
        finishInteractionWhileLocked(interaction);
        os_unfair_lock_unlock(&interaction->lock);
        return contactCount;
    }
    os_unfair_lock_unlock(&interaction->lock);
    return 0;
}

void MGMouseClickInteractionBegin(MGMouseClickInteraction *interaction,
                                  double timestamp) {
    os_unfair_lock_lock(&interaction->lock);
    interaction->active = YES;
    interaction->handled = NO;
    interaction->dragged = NO;
    interaction->released = NO;
    interaction->peakContactCount = interaction->currentContactCount;
    interaction->mouseDownTime = timestamp;
    os_unfair_lock_unlock(&interaction->lock);
}

void MGMouseClickInteractionMarkHandled(MGMouseClickInteraction *interaction) {
    os_unfair_lock_lock(&interaction->lock);
    interaction->handled = YES;
    os_unfair_lock_unlock(&interaction->lock);
}

void MGMouseClickInteractionRecordDrag(MGMouseClickInteraction *interaction) {
    os_unfair_lock_lock(&interaction->lock);
    interaction->dragged = YES;
    os_unfair_lock_unlock(&interaction->lock);
}

int MGMouseClickInteractionFinish(MGMouseClickInteraction *interaction) {
    os_unfair_lock_lock(&interaction->lock);
    BOOL eligible = interaction->peakContactCount == 2 ||
        interaction->peakContactCount == 3;
    int contactCount = interaction->active && !interaction->handled &&
        !interaction->dragged && eligible ? interaction->peakContactCount : 0;
    if (contactCount > 0 || interaction->handled || interaction->dragged)
        finishInteractionWhileLocked(interaction);
    else
        interaction->released = YES;
    os_unfair_lock_unlock(&interaction->lock);
    return contactCount;
}
