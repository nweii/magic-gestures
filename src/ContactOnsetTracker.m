// Preserves first-contact times while contacts remain active in a raw hardware sequence.
// The tracker is device-agnostic and leaves geometry, pressure, and motion to each recognizer.

#import "ContactOnsetTracker.h"

#include <float.h>

static BOOL containsIdentifier(const int *identifiers, int count, int identifier) {
    for (int index = 0; index < count; index++) {
        if (identifiers[index] == identifier)
            return YES;
    }
    return NO;
}

void MGContactOnsetTrackerObserve(MGContactOnsetTracker *tracker,
                                  const int *identifiers, int count,
                                  double timestamp) {
    int limitedCount = MIN(MAX(count, 0), 16);

    for (NSUInteger index = 0; index < tracker->count;) {
        if (containsIdentifier(identifiers, limitedCount, tracker->identifiers[index])) {
            index++;
            continue;
        }
        NSUInteger last = tracker->count - 1;
        tracker->identifiers[index] = tracker->identifiers[last];
        tracker->firstSeenTimes[index] = tracker->firstSeenTimes[last];
        tracker->count--;
    }

    for (int index = 0; index < limitedCount; index++) {
        if (containsIdentifier(tracker->identifiers, (int)tracker->count, identifiers[index]))
            continue;
        tracker->identifiers[tracker->count] = identifiers[index];
        tracker->firstSeenTimes[tracker->count] = timestamp;
        tracker->count++;
    }
}

BOOL MGContactOnsetTrackerContactsArrivedWithin(const MGContactOnsetTracker *tracker,
                                                const int *identifiers, int count,
                                                double maximumSpread) {
    if (count < 2 || maximumSpread < 0)
        return NO;

    double earliest = DBL_MAX;
    double latest = -DBL_MAX;
    for (int index = 0; index < count; index++) {
        BOOL found = NO;
        for (NSUInteger trackerIndex = 0; trackerIndex < tracker->count; trackerIndex++) {
            if (tracker->identifiers[trackerIndex] != identifiers[index])
                continue;
            earliest = MIN(earliest, tracker->firstSeenTimes[trackerIndex]);
            latest = MAX(latest, tracker->firstSeenTimes[trackerIndex]);
            found = YES;
            break;
        }
        if (!found)
            return NO;
    }
    return latest - earliest <= maximumSpread;
}
