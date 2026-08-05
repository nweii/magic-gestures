// Implements guided trace progression independently from AppKit and hardware callbacks.

#import "TraceSessionModel.h"

@interface MGTraceSessionModel () {
    MGTraceSessionPhase _phase;
    NSInteger _stepIndex;
    NSInteger _countdown;
    NSArray *_steps;
}
@end

@implementation MGTraceSessionModel

@synthesize phase = _phase, stepIndex = _stepIndex, countdown = _countdown, steps = _steps;

- (instancetype)initWithSteps:(NSArray *)steps {
    self = [super init];
    if (self) {
        _steps = [steps copy];
        _phase = MGTraceSessionOverview;
        _stepIndex = -1;
    }
    return self;
}

- (void)dealloc { [_steps release]; [super dealloc]; }
- (BOOL)labelsEnabled { return _phase == MGTraceSessionReadyForLabel; }

- (void)beginProtocol {
    if (_phase != MGTraceSessionOverview) return;
    _stepIndex = 0;
    _phase = [_steps count] == 0 ? MGTraceSessionComplete : MGTraceSessionPreparing;
}

- (void)beginCountdown {
    if (_phase != MGTraceSessionPreparing) return;
    _countdown = 3;
    _phase = MGTraceSessionCountdown;
}

- (BOOL)tickCountdown {
    if (_phase != MGTraceSessionCountdown) return NO;
    _countdown--;
    if (_countdown <= 0) {
        _countdown = 0;
        _phase = MGTraceSessionRecording;
        return YES;
    }
    return NO;
}

- (void)observeCapturing:(BOOL)capturing awaitingLabel:(BOOL)awaitingLabel
             sawContacts:(BOOL)sawContacts {
    if (awaitingLabel) _phase = MGTraceSessionReadyForLabel;
    else if (capturing && sawContacts) _phase = MGTraceSessionWaitingForLift;
    else if (capturing) _phase = MGTraceSessionRecording;
}

- (void)markCurrentStep {
    if (![self labelsEnabled]) return;
    _stepIndex++;
    _phase = _stepIndex >= (NSInteger)[_steps count]
        ? MGTraceSessionComplete : MGTraceSessionPreparing;
}

- (void)retryCurrentStep {
    if (![self labelsEnabled]) return;
    _phase = MGTraceSessionPreparing;
}

@end
