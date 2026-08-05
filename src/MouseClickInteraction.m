// Tracks one Magic Mouse physical click across the CG event and touch-frame streams.

#import "MouseClickInteraction.h"

static const double kMouseClickContactArrivalGrace = 0.10;
static const int kMouseClickDragThreshold = 4;

static void finishInteractionWhileLocked(MGMouseClickInteraction *interaction) {
    interaction->active = NO;
    interaction->handled = NO;
    interaction->dragged = NO;
    interaction->released = NO;
    interaction->cumulativeDeltaX = 0;
    interaction->cumulativeDeltaY = 0;
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
    interaction->cumulativeDeltaX = 0;
    interaction->cumulativeDeltaY = 0;
    interaction->mouseDownTime = -1;
    interaction->rawFrameGeneration = 0;
    interaction->eligibleFrameGeneration = 0;
    interaction->rawContactCount = 0;
    os_unfair_lock_unlock(&interaction->lock);
}

void MGMouseClickInteractionObserveRawContacts(MGMouseClickInteraction *interaction,
                                               int rawContactCount) {
    os_unfair_lock_lock(&interaction->lock);
    interaction->rawFrameGeneration++;
    interaction->rawContactCount = rawContactCount;
    os_unfair_lock_unlock(&interaction->lock);
}

int MGMouseClickInteractionObserveContacts(MGMouseClickInteraction *interaction,
                                           int eligibleContactCount,
                                           double timestamp) {
    os_unfair_lock_lock(&interaction->lock);
    interaction->currentContactCount = eligibleContactCount;
    interaction->eligibleFrameGeneration = interaction->rawFrameGeneration;
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

MGMouseClickEligibilitySnapshot MGMouseClickInteractionEligibilitySnapshot(
    MGMouseClickInteraction *interaction) {
    os_unfair_lock_lock(&interaction->lock);
    MGMouseClickEligibilitySnapshot snapshot = {
        .stage = MGMouseClickEligibilityNoRawContacts,
        .rawContactCount = interaction->rawContactCount,
        .eligibleContactCount = interaction->currentContactCount,
    };
    if (interaction->rawContactCount > 0 &&
        interaction->eligibleFrameGeneration != interaction->rawFrameGeneration) {
        snapshot.stage = MGMouseClickEligibilityFilterPending;
    } else if (interaction->currentContactCount == 2 ||
               interaction->currentContactCount == 3) {
        snapshot.stage = MGMouseClickEligibilityAvailable;
    } else if (interaction->rawContactCount > 0) {
        snapshot.stage = MGMouseClickEligibilityFilteredOut;
    }
    os_unfair_lock_unlock(&interaction->lock);
    return snapshot;
}

int MGMouseClickReplacementContactCount(MGMouseClickEligibilitySnapshot snapshot,
                                        BOOL hasTwoFingerBinding,
                                        BOOL hasThreeFingerBinding) {
    if (snapshot.stage != MGMouseClickEligibilityAvailable)
        return 0;
    if (snapshot.eligibleContactCount == 2 && hasTwoFingerBinding)
        return 2;
    if (snapshot.eligibleContactCount == 3 && hasThreeFingerBinding)
        return 3;
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
    interaction->cumulativeDeltaX = 0;
    interaction->cumulativeDeltaY = 0;
    interaction->mouseDownTime = timestamp;
    os_unfair_lock_unlock(&interaction->lock);
}

void MGMouseClickInteractionMarkHandled(MGMouseClickInteraction *interaction) {
    os_unfair_lock_lock(&interaction->lock);
    interaction->handled = YES;
    os_unfair_lock_unlock(&interaction->lock);
}

void MGMouseClickInteractionRecordDrag(MGMouseClickInteraction *interaction,
                                       int deltaX, int deltaY) {
    os_unfair_lock_lock(&interaction->lock);
    if (interaction->active && !interaction->dragged) {
        interaction->cumulativeDeltaX += deltaX;
        interaction->cumulativeDeltaY += deltaY;
        int distanceSquared = interaction->cumulativeDeltaX * interaction->cumulativeDeltaX +
            interaction->cumulativeDeltaY * interaction->cumulativeDeltaY;
        interaction->dragged = distanceSquared >=
            kMouseClickDragThreshold * kMouseClickDragThreshold;
    }
    os_unfair_lock_unlock(&interaction->lock);
}

BOOL MGMouseClickInteractionHasDragged(MGMouseClickInteraction *interaction) {
    os_unfair_lock_lock(&interaction->lock);
    BOOL dragged = interaction->dragged;
    os_unfair_lock_unlock(&interaction->lock);
    return dragged;
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
