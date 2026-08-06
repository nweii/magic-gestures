// Reports the multi-touch motions macOS has already claimed, so a configured
// binding that shares a motion with a built-in gesture can be named at reload.

#import <Foundation/Foundation.h>

// Answers what a preference domain says about one motion. A key macOS has never
// written is Unknown rather than Free, because the built-in default still
// applies and the value alone cannot reveal it.
typedef NS_ENUM(NSInteger, MGSystemGestureClaim) {
    MGSystemGestureClaimUnknown = 0,
    MGSystemGestureClaimFree,
    MGSystemGestureClaimTaken,
};

MGSystemGestureClaim MGSystemGestureClaimForValue(NSNumber *value);

// One warning per configured slug that shares a motion with a claimed built-in
// gesture, phrased for the menu. `valueForKey` answers the preference value for
// a key, or nil when no domain carries it.
NSArray *MGSystemGestureConflicts(NSSet *configuredMouseSlugs,
                                  NSSet *configuredTrackpadSlugs,
                                  NSNumber *(^valueForKey)(NSString *domains, NSString *key));

// As above, reading the macOS mouse and trackpad preference domains.
NSArray *MGSystemGestureConflictsForCurrentUser(NSSet *configuredMouseSlugs,
                                                NSSet *configuredTrackpadSlugs);

// Every preference key paired with one slug it overlaps, as sorted
// "device domain key slug" lines. scripts/check.sh diffs these against
// scripts/system-gestures.sh so the two cannot describe different conflicts.
NSArray *MGSystemGestureClaimTableLines(void);

// The macOS release whose interface supplied the setting names and locations in
// the warnings. Apple rarely moves these between releases, so this records what
// was checked rather than gating anything, and gives a later reader a date to
// measure staleness against. Returns a sentence naming that release, and saying
// the running release is newer when it is.
NSString *MGSystemGestureSettingsProvenance(void);
