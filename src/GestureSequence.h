// Declares the small ownership primitive that keeps one touch sequence from dispatching competing gestures.

#import <Foundation/Foundation.h>

typedef struct {
    NSUInteger owner;
    BOOL suppressNativeScroll;
} MGGestureSequence;

void MGGestureSequenceInitialize(MGGestureSequence *sequence);
BOOL MGGestureSequenceTryClaim(MGGestureSequence *sequence, NSUInteger owner);
void MGGestureSequenceObserveBoundScrollFamily(MGGestureSequence *sequence,
                                               int activeContactCount,
                                               int requiredContactCount,
                                               BOOL hasBinding);
BOOL MGGestureSequenceSuppressesNativeScroll(const MGGestureSequence *sequence);
void MGGestureSequenceFinishFrame(MGGestureSequence *sequence, int activeContactCount);
