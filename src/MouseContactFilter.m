// Rejects narrow resting contacts at either side of a Magic Mouse touch surface.

#import "MouseContactFilter.h"

#include <math.h>

static const float kRestingEdgeInset = 0.10;
static const float kRestingEdgeMaximumSize = 1.0;
static const float kRestingEdgeMaximumMinorAxis = 7.0;
static const float kClickNeighborDistanceSquared = 0.25;

BOOL MGMagicMouseContactShouldBeExcluded(float x, float y, float size,
                                         float minorAxis, float minimumY) {
    if (y < minimumY)
        return YES;
    float edgeDistance = MIN(x, 1.0f - x);
    return edgeDistance < kRestingEdgeInset &&
           size <= kRestingEdgeMaximumSize &&
           minorAxis < kRestingEdgeMaximumMinorAxis;
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
