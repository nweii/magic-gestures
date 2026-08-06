// Rejects narrow resting contacts at either side of a Magic Mouse touch surface.

#import "MouseContactFilter.h"

#include <math.h>

static const float kRestingEdgeInset = 0.10;
static const float kRestingEdgeMaximumSize = 1.0;
static const float kRestingEdgeMaximumMinorAxis = 7.0;
static const float kClickNeighborDistanceSquared = 0.25;
static const float kClickMinimumY = 0.30;
static const float kThumbRegionMaximumY = 0.6;
static const float kThumbRegionMaximumX = 0.15;
static const float kThumbBelowFingersMinimumGap = 0.12;

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

// A thumb gripping the lower-left corner sits well below the fingertips on
// top of the mouse. The index finger of a level three-finger row can land in
// the same corner region, so the corner box alone cannot identify a thumb:
// with other contacts present, the candidate must also sit clearly below the
// next-lowest contact. A lone contact in the region keeps counting as a thumb
// so the single-finger Thumb gesture still fires.
BOOL MGMagicMouseLowestContactIsThumb(float x, float y, float nextLowestY,
                                      int contactCount) {
    if (y > kThumbRegionMaximumY || x > kThumbRegionMaximumX)
        return NO;
    if (contactCount <= 1)
        return YES;
    return nextLowestY - y >= kThumbBelowFingersMinimumGap;
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
