// Owns exclusive gesture dispatch within one continuous touch sequence.

#import "GestureSequence.h"

void MGGestureSequenceInitialize(MGGestureSequence *sequence) {
    sequence->owner = 0;
}

BOOL MGGestureSequenceTryClaim(MGGestureSequence *sequence, NSUInteger owner) {
    if (owner == 0)
        return NO;
    if (sequence->owner == 0)
        sequence->owner = owner;
    return sequence->owner == owner;
}

void MGGestureSequenceFinishFrame(MGGestureSequence *sequence, int activeContactCount) {
    if (activeContactCount == 0)
        MGGestureSequenceInitialize(sequence);
}
