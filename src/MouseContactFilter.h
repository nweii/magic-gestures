// Declares Magic Mouse contact-quality rules shared by physical-click recognition.

#import <Foundation/Foundation.h>

BOOL MGMagicMouseContactShouldBeExcluded(float x, float y, float size,
                                         float minorAxis, float minimumY);
BOOL MGMagicMouseContactsFormClickCluster(const float *xs, const float *ys,
                                          int contactCount);
