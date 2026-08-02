// Declares the bounded, privacy-safe recorder used by guided hardware trace sessions.

#import <Foundation/Foundation.h>

typedef struct {
    int identifier;
    int state;
    double x;
    double y;
    double size;
    double majorAxis;
    double minorAxis;
    double density;
} MGTraceContact;

BOOL MGTraceStart(NSString *bundlePath, NSString **problem);
BOOL MGTraceIsActive(void);
BOOL MGTraceSuppressesActions(void);
NSString *MGTraceBundlePath(void);
NSDictionary *MGTraceStatus(void);
void MGTraceBeginStep(NSString *step, NSString *requested,
                      BOOL expectsDispatch, NSString *instruction);
void MGTraceMarkStep(NSString *label);
void MGTraceStop(void);

void MGTraceRecordMouseFrame(const void *device, double hardwareTimestamp,
                             int frame, const MGTraceContact *contacts,
                             int contactCount);
void MGTraceRecordFilterDecision(int identifier, NSString *reason, BOOL kept,
                                 double x, double y, double size,
                                 double majorAxis, double minorAxis);
void MGTraceRecordCGEvent(NSString *event, double pressure,
                          int64_t axis1, int64_t axis2, NSString *disposition);
void MGTraceRecordCandidate(NSString *gesture, NSString *phase,
                            NSString *reason);
void MGTraceRecordOwnership(NSString *requested, NSString *previous,
                            NSString *result, BOOL accepted);
void MGTraceRecordDispatch(NSString *gesture, NSString *scope,
                           NSString *actionKind, NSString *outcome);

// Test seam: serializes one already-safe envelope with stable key ordering.
NSData *MGTraceDeterministicJSONLine(NSDictionary *event, NSString **problem);
