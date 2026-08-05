// Rejects narrow resting contacts at either side of a Magic Mouse touch surface.

#import "MouseContactFilter.h"

#include <math.h>

static const float kRestingEdgeInset = 0.10;
static const float kRestingEdgeMaximumSize = 1.0;
static const float kRestingEdgeMaximumMinorAxis = 7.0;
static const float kClickNeighborDistanceSquared = 0.25;
static const float kClickMinimumY = 0.30;

BOOL MGMagicMouseContactShouldBeExcluded(float x, float y, float size,
                                         float minorAxis) {
    return MGMagicMouseContactDecisionForGeometry(x, y, size, minorAxis) !=
        MGMagicMouseContactKept;
}

MGMagicMouseContactDecision MGMagicMouseContactDecisionForGeometry(float x, float y,
                                                                    float size,
                                                                    float minorAxis) {
    BOOL narrowRestingContact = size <= kRestingEdgeMaximumSize &&
        minorAxis < kRestingEdgeMaximumMinorAxis;
    if (y < kClickMinimumY && narrowRestingContact)
        return MGMagicMouseContactExcludedRearNarrow;
    float edgeDistance = MIN(x, 1.0f - x);
    if (edgeDistance < kRestingEdgeInset && narrowRestingContact)
        return MGMagicMouseContactExcludedSideNarrow;
    return MGMagicMouseContactKept;
}

NSString *MGMagicMouseContactDecisionName(MGMagicMouseContactDecision decision) {
    switch (decision) {
        case MGMagicMouseContactExcludedRearNarrow: return @"rear-narrow";
        case MGMagicMouseContactExcludedSideNarrow: return @"side-narrow";
        case MGMagicMouseContactKept: return @"kept";
    }
    return @"unknown";
}

BOOL MGMagicMouseContactsFormClickCluster(const float *xs, const float *ys,
                                          int contactCount) {
    if (contactCount <= 1)
        return YES;
    if (contactCount > 16)
        return NO;

    BOOL reached[16] = {YES};
    BOOL changed = YES;
    while (changed) {
        changed = NO;
        for (int i = 0; i < contactCount; i++) {
            if (!reached[i])
                continue;
            for (int j = 0; j < contactCount; j++) {
                if (reached[j])
                    continue;
                float dx = xs[i] - xs[j];
                float dy = ys[i] - ys[j];
                if (dx * dx + dy * dy <= kClickNeighborDistanceSquared) {
                    reached[j] = YES;
                    changed = YES;
                }
            }
        }
    }

    for (int i = 0; i < contactCount; i++) {
        if (!reached[i])
            return NO;
    }
    return YES;
}

int MGMagicMouseClusteredThirdFingerIndex(
    const float *xs, const float *ys,
    const MGMagicMouseContactDecision *decisions, int contactCount) {
    if (contactCount != 3)
        return -1;
    int keptCount = 0;
    int sideContactIndex = -1;
    for (int i = 0; i < contactCount; i++) {
        if (decisions[i] == MGMagicMouseContactKept)
            keptCount++;
        else if (decisions[i] == MGMagicMouseContactExcludedSideNarrow) {
            if (sideContactIndex >= 0)
                return -1;
            sideContactIndex = i;
        } else {
            return -1;
        }
    }
    if (keptCount != 2 || sideContactIndex < 0)
        return -1;
    return MGMagicMouseContactsFormClickCluster(xs, ys, contactCount)
        ? sideContactIndex : -1;
}
