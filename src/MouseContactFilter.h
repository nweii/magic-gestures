// Declares Magic Mouse contact-quality rules shared by physical-click recognition.

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MGMagicMouseContactDecision) {
    MGMagicMouseContactKept = 0,
    MGMagicMouseContactExcludedRearNarrow,
    MGMagicMouseContactExcludedSideNarrow,
};

MGMagicMouseContactDecision MGMagicMouseContactDecisionForGeometry(float x, float y,
                                                                    float size,
                                                                    float minorAxis);
NSString *MGMagicMouseContactDecisionName(MGMagicMouseContactDecision decision);
BOOL MGMagicMouseContactShouldBeExcluded(float x, float y, float size,
                                         float minorAxis);
BOOL MGMagicMouseContactsFormClickCluster(const float *xs, const float *ys,
                                          int contactCount);
