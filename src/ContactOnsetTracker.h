// Tracks when individual contacts first appear during one raw hardware sequence.
// Recognizers use it when a gesture requires several contacts to arrive together.

#import <Foundation/Foundation.h>

typedef struct {
    int identifiers[16];
    double firstSeenTimes[16];
    NSUInteger count;
} MGContactOnsetTracker;

void MGContactOnsetTrackerObserve(MGContactOnsetTracker *tracker,
                                  const int *identifiers, int count,
                                  double timestamp);
BOOL MGContactOnsetTrackerContactsArrivedWithin(const MGContactOnsetTracker *tracker,
                                                const int *identifiers, int count,
                                                double maximumSpread);
