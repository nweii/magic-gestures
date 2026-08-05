// Checks guided trace state transitions and label gating without UI automation.

#import <Foundation/Foundation.h>
#import "TraceSessionModel.h"

static void require(BOOL condition, NSString *message) {
    if (!condition) { fprintf(stderr, "FAIL  %s\n", [message UTF8String]); exit(1); }
}

int main(void) {
    @autoreleasepool {
        MGTraceSessionModel *model = [[[MGTraceSessionModel alloc]
            initWithSteps:@[@{@"id": @"one"}, @{@"id": @"two"}]] autorelease];
        require(model.phase == MGTraceSessionOverview && !model.labelsEnabled,
                @"session did not begin at the overview");
        [model beginProtocol];
        require(model.phase == MGTraceSessionPreparing && model.stepIndex == 0,
                @"protocol did not prepare its first step");
        [model beginCountdown];
        require(model.phase == MGTraceSessionCountdown && model.countdown == 3,
                @"neutral countdown did not begin at three seconds");
        require(![model tickCountdown] && model.countdown == 2,
                @"countdown ended one tick early");
        require(![model tickCountdown] && model.countdown == 1,
                @"countdown ended two ticks early");
        require([model tickCountdown] && model.phase == MGTraceSessionRecording,
                @"countdown did not enter recording");
        [model observeCapturing:YES awaitingLabel:NO sawContacts:YES];
        require(model.phase == MGTraceSessionWaitingForLift && !model.labelsEnabled,
                @"contact activity enabled labels before lift");
        [model observeCapturing:NO awaitingLabel:YES sawContacts:YES];
        require(model.labelsEnabled, @"closed scored window did not enable labels");
        [model retryCurrentStep];
        require(model.phase == MGTraceSessionPreparing && model.stepIndex == 0,
                @"botched attempt did not prepare the same step for retry");
        [model beginCountdown]; [model tickCountdown]; [model tickCountdown]; [model tickCountdown];
        [model observeCapturing:NO awaitingLabel:YES sawContacts:YES];
        [model markCurrentStep];
        require(model.phase == MGTraceSessionPreparing && model.stepIndex == 1,
                @"label did not advance exactly one step");
        [model beginCountdown]; [model tickCountdown]; [model tickCountdown]; [model tickCountdown];
        [model observeCapturing:NO awaitingLabel:YES sawContacts:YES];
        [model markCurrentStep];
        require(model.phase == MGTraceSessionComplete && !model.labelsEnabled,
                @"final label did not complete the protocol");
        printf("trace session model: all checks passed\n");
    }
    return 0;
}
