// Recognizes a bounded, stationary tap after an exact number of contacts fully lifts.

#import "ContactTapRecognizer.h"

#include <math.h>

static const double kMinimumTapDuration = 0.020;
static const double kMaximumTapDuration = 0.350;
static const double kMaximumContactArrival = 0.050;
static const float kMaximumCentroidMovementSquared = 0.000225;

void MGContactTapRecognizerInitialize(MGContactTapRecognizer *recognizer,
                                     int targetCount) {
    recognizer->targetCount = targetCount;
    recognizer->active = NO;
    recognizer->reachedTarget = NO;
    recognizer->rejected = NO;
    recognizer->startTime = -1;
    recognizer->targetCentroidX = 0;
    recognizer->targetCentroidY = 0;
}

BOOL MGContactTapRecognizerUpdate(MGContactTapRecognizer *recognizer,
                                  int contactCount,
                                  float centroidX,
                                  float centroidY,
                                  BOOL eligible,
                                  double timestamp) {
    if (contactCount == 0) {
        BOOL recognized = recognizer->active && recognizer->reachedTarget &&
            !recognizer->rejected &&
            timestamp - recognizer->startTime >= kMinimumTapDuration &&
            timestamp - recognizer->startTime <= kMaximumTapDuration;
        int targetCount = recognizer->targetCount;
        MGContactTapRecognizerInitialize(recognizer, targetCount);
        return recognized;
    }

    if (!recognizer->active) {
        recognizer->active = YES;
        recognizer->startTime = timestamp;
    }

    if (!eligible)
        recognizer->rejected = YES;

    if (contactCount > recognizer->targetCount ||
        timestamp - recognizer->startTime > kMaximumTapDuration) {
        recognizer->rejected = YES;
    } else if (!recognizer->reachedTarget && contactCount == recognizer->targetCount) {
        if (timestamp - recognizer->startTime > kMaximumContactArrival) {
            recognizer->rejected = YES;
        } else {
            recognizer->reachedTarget = YES;
            recognizer->targetCentroidX = centroidX;
            recognizer->targetCentroidY = centroidY;
        }
    } else if (recognizer->reachedTarget && contactCount == recognizer->targetCount) {
        float dx = centroidX - recognizer->targetCentroidX;
        float dy = centroidY - recognizer->targetCentroidY;
        if (dx * dx + dy * dy > kMaximumCentroidMovementSquared)
            recognizer->rejected = YES;
    }

    return NO;
}
