// Defines the testable state machine for one guided Magic Mouse trace session.

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MGTraceSessionPhase) {
    MGTraceSessionOverview,
    MGTraceSessionPreparing,
    MGTraceSessionCountdown,
    MGTraceSessionRecording,
    MGTraceSessionWaitingForLift,
    MGTraceSessionReadyForLabel,
    MGTraceSessionComplete,
};

@interface MGTraceSessionModel : NSObject
@property(nonatomic, readonly) MGTraceSessionPhase phase;
@property(nonatomic, readonly) NSInteger stepIndex;
@property(nonatomic, readonly) NSInteger countdown;
@property(nonatomic, readonly) NSArray *steps;
@property(nonatomic, readonly) BOOL labelsEnabled;
- (instancetype)initWithSteps:(NSArray *)steps;
- (void)beginProtocol;
- (void)beginCountdown;
- (BOOL)tickCountdown;
- (void)observeCapturing:(BOOL)capturing awaitingLabel:(BOOL)awaitingLabel
             sawContacts:(BOOL)sawContacts;
- (void)markCurrentStep;
@end
