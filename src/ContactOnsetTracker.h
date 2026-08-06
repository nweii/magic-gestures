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

// Answers whether `arrival` appeared more than `lead` after `anchor`, which is
// how a recognizer requires one contact to have been held before another lands.
// The comparison is strict, so passing the same interval both here and to
// MGContactOnsetTrackerContactsArrivedWithin leaves the two answers disjoint:
// one pair of contacts cannot read as both simultaneous and led. A contact the
// tracker has not seen answers NO.
BOOL MGContactOnsetTrackerContactArrivedAfter(const MGContactOnsetTracker *tracker,
                                              int anchor, int arrival, double lead);
