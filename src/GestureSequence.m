// Owns exclusive gesture dispatch within one continuous touch sequence.

#import "GestureSequence.h"

void MGGestureSequenceInitialize(MGGestureSequence *sequence) {
    sequence->owner = 0;
    sequence->suppressNativeScroll = NO;
}

BOOL MGGestureSequenceTryClaim(MGGestureSequence *sequence, NSUInteger owner) {
    if (owner == 0)
        return NO;
    if (sequence->owner == 0)
        sequence->owner = owner;
    return sequence->owner == owner;
}

void MGGestureSequenceObserveBoundScrollFamily(MGGestureSequence *sequence,
                                               int activeContactCount,
                                               int requiredContactCount,
                                               BOOL hasBinding) {
    if (hasBinding && activeContactCount == requiredContactCount)
        sequence->suppressNativeScroll = YES;
}

BOOL MGGestureSequenceSuppressesNativeScroll(const MGGestureSequence *sequence) {
    return sequence->suppressNativeScroll;
}

void MGGestureSequenceFinishFrame(MGGestureSequence *sequence, int activeContactCount) {
    if (activeContactCount == 0)
        MGGestureSequenceInitialize(sequence);
}
