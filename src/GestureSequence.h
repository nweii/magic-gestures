// Declares the small ownership primitive that keeps one touch sequence from dispatching competing gestures.

#import <Foundation/Foundation.h>

typedef struct {
    NSUInteger owner;
} MGGestureSequence;

void MGGestureSequenceInitialize(MGGestureSequence *sequence);
BOOL MGGestureSequenceTryClaim(MGGestureSequence *sequence, NSUInteger owner);
void MGGestureSequenceFinishFrame(MGGestureSequence *sequence, int activeContactCount);
