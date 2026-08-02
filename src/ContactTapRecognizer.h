// Declares a reusable recognizer for an exact-count stationary contact tap.

#import <Foundation/Foundation.h>

typedef struct {
    int targetCount;
    BOOL active;
    BOOL reachedTarget;
    BOOL rejected;
    double startTime;
    float targetCentroidX;
    float targetCentroidY;
} MGContactTapRecognizer;

void MGContactTapRecognizerInitialize(MGContactTapRecognizer *recognizer,
                                     int targetCount);
BOOL MGContactTapRecognizerUpdate(MGContactTapRecognizer *recognizer,
                                  int contactCount,
                                  float centroidX,
                                  float centroidY,
                                  BOOL eligible,
                                  double timestamp);
