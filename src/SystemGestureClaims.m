// Maps macOS multi-touch preference keys to the gesture slugs whose motion they
// overlap, and phrases the overlap for a reader deciding whether to rebind.

#import "SystemGestureClaims.h"

// One built-in gesture, and the configuration slugs whose motion it shares.
//
// `domains` are the preference domains that answer for `key`, in order. macOS
// assigns touch gestures in more than one domain, and the Trackpad pane is not
// the only place a trackpad gesture is turned on.
// `disqualifier` is a second key that, when non-zero, means the setting is on
// but assigned to a different motion, so the entry does not apply.
// `setting`, `motion`, and `location` quote the macOS interface, so a reader
// comparing a warning against System Settings sees the same words in both. A
// NULL `setting` means the label is unconfirmed and the motion stands alone.
// `startsWithBoundTap` marks a built-in double tap, whose opening tap is the
// single tap a binding uses. That is the overlap a reader most easily misses.
//
// scripts/check.sh holds this table and scripts/system-gestures.sh to the same
// device, domain, key, and slug rows.
typedef struct {
    const char *domains;
    const char *key;
    const char *disqualifier;
    const char *slugs;
    const char *setting;
    const char *motion;
    const char *location;
    BOOL startsWithBoundTap;
    BOOL trackpad;
} MGSystemGestureEntry;

#define MOUSE_DOMAINS "com.apple.AppleMultitouchMouse"
#define TRACKPAD_DOMAINS "com.apple.driver.AppleBluetoothMultitouch.trackpad,com.apple.AppleMultitouchTrackpad"

// A setting is named only where its pane holds exactly one gesture using that
// motion. Where two settings can share a motion, a NULL name keeps the warning
// to the motion rather than guessing which one the reader will find.
//
// Pinch and spread appear on the trackpad alone. A Magic Mouse has no room for
// the thumb those gestures need.
static const MGSystemGestureEntry kEntries[] = {
    {MOUSE_DOMAINS, "MouseOneFingerDoubleTapGesture", NULL, "one-finger-tap",
     "Smart zoom", "Double-tap with One Finger", "Mouse > Point & Click", YES, NO},
    {MOUSE_DOMAINS, "MouseTwoFingerDoubleTapGesture", NULL, "two-finger-tap",
     "Mission Control", "Double-tap with Two Fingers", "Mouse > More Gestures", YES, NO},
    {MOUSE_DOMAINS, "MouseTwoFingerHorizSwipeGesture", NULL,
     "two-finger-swipe-left,two-finger-swipe-right",
     "Swipe between full-screen applications", "Swipe Left or Right with Two Fingers",
     "Mouse > More Gestures", NO, NO},
    {MOUSE_DOMAINS, "MouseHorizontalScroll", NULL,
     "one-finger-swipe-left,one-finger-swipe-right",
     "Swipe between pages", "Scroll Left or Right with One Finger",
     "Mouse > More Gestures", NO, NO},

    {TRACKPAD_DOMAINS, "TrackpadTwoFingerDoubleTapGesture", NULL, "two-finger-tap",
     "Smart zoom", "Double-tap with two fingers", "Trackpad > Scroll & Zoom", YES, YES},
    // Secondary click stays on while moving to a corner, so the setting being
    // enabled does not by itself mean it still uses a two-finger tap.
    {TRACKPAD_DOMAINS, "TrackpadRightClick", "TrackpadCornerSecondaryClick",
     "two-finger-tap",
     "Secondary click", "Click or Tap with Two Fingers", "Trackpad > Point & Click", NO, YES},
    {TRACKPAD_DOMAINS, "TrackpadThreeFingerTapGesture", NULL, "three-finger-tap",
     "Look up & data detectors", "Tap with Three Fingers", "Trackpad > Point & Click", NO, YES},
    {TRACKPAD_DOMAINS, "TrackpadThreeFingerHorizSwipeGesture", NULL,
     "three-finger-swipe-left,three-finger-swipe-right",
     "Swipe between full-screen applications", "Swipe Left or Right with Three Fingers",
     "Trackpad > More Gestures", NO, YES},
    {TRACKPAD_DOMAINS, "TrackpadFourFingerHorizSwipeGesture", NULL,
     "four-finger-swipe-left,four-finger-swipe-right",
     "Swipe between full-screen applications", "Swipe Left or Right with Four Fingers",
     "Trackpad > More Gestures", NO, YES},
    // One key answers for both directions, and each names its own setting.
    {TRACKPAD_DOMAINS, "TrackpadThreeFingerVertSwipeGesture", NULL, "three-finger-swipe-up",
     "Mission Control", "Swipe Up with Three Fingers", "Trackpad > More Gestures", NO, YES},
    {TRACKPAD_DOMAINS, "TrackpadThreeFingerVertSwipeGesture", NULL, "three-finger-swipe-down",
     "App Exposé", "Swipe Down with Three Fingers", "Trackpad > More Gestures", NO, YES},
    {TRACKPAD_DOMAINS, "TrackpadFourFingerVertSwipeGesture", NULL, "four-finger-swipe-up",
     "Mission Control", "Swipe Up with Four Fingers", "Trackpad > More Gestures", NO, YES},
    {TRACKPAD_DOMAINS, "TrackpadFourFingerVertSwipeGesture", NULL, "four-finger-swipe-down",
     "App Exposé", "Swipe Down with Four Fingers", "Trackpad > More Gestures", NO, YES},
    {TRACKPAD_DOMAINS, "TrackpadThreeFingerDrag", NULL,
     "three-finger-swipe-left,three-finger-swipe-right,three-finger-swipe-up,three-finger-swipe-down",
     "Three Finger Drag", "drag with three fingers",
     "Accessibility > Pointer Control > Trackpad Options", NO, YES},
    {TRACKPAD_DOMAINS, "TrackpadFourFingerPinchGesture", NULL,
     "index-to-pinky,pinky-to-index",
     NULL, "a pinch with thumb and three fingers", "Trackpad > More Gestures", NO, YES},
    {TRACKPAD_DOMAINS, "TrackpadFiveFingerPinchGesture", NULL,
     "index-to-pinky,pinky-to-index",
     "Show Desktop", "Spread with thumb and three fingers", "Trackpad > More Gestures", NO, YES},
    // Display magnification, which enlarges the whole screen rather than
    // content inside an app the way Smart zoom does.
    {"com.apple.universalaccess", "closeViewTrackpadGestureZoomEnabled", NULL,
     "three-finger-tap", "Use trackpad gesture to zoom",
     "Double-tap three fingers to toggle zoom", "Accessibility > Zoom", YES, YES},
};

static const size_t kEntryCount = sizeof(kEntries) / sizeof(kEntries[0]);

MGSystemGestureClaim MGSystemGestureClaimForValue(NSNumber *value) {
    if (value == nil)
        return MGSystemGestureClaimUnknown;
    return [value integerValue] == 0 ? MGSystemGestureClaimFree : MGSystemGestureClaimTaken;
}

NSArray *MGSystemGestureConflicts(NSSet *configuredMouseSlugs,
                                  NSSet *configuredTrackpadSlugs,
                                  NSNumber *(^valueForKey)(NSString *domains, NSString *key)) {
    // One binding can collide with several built-in gestures, so findings group
    // under the binding they concern. Reporting each collision as its own
    // paragraph produced near-identical blocks that read as a rendering fault.
    NSMutableArray *order = [NSMutableArray array];
    NSMutableDictionary *bulletsByBinding = [NSMutableDictionary dictionary];
    for (size_t i = 0; i < kEntryCount; i++) {
        const MGSystemGestureEntry entry = kEntries[i];
        NSString *domains = [NSString stringWithUTF8String:entry.domains];
        if (MGSystemGestureClaimForValue(valueForKey(domains,
                [NSString stringWithUTF8String:entry.key])) != MGSystemGestureClaimTaken)
            continue;
        if (entry.disqualifier != NULL &&
            MGSystemGestureClaimForValue(valueForKey(domains,
                [NSString stringWithUTF8String:entry.disqualifier])) ==
                MGSystemGestureClaimTaken)
            continue;
        NSSet *configured = entry.trackpad ? configuredTrackpadSlugs : configuredMouseSlugs;
        NSString *device = entry.trackpad ? @"Trackpad" : @"Mouse";
        NSString *motion = [NSString stringWithUTF8String:entry.motion];
        // The macOS gesture leads, then its motion in Apple's own words. Naming
        // the owner of each part keeps the reader from having to work out which
        // gesture is theirs. A shared motion needs no explaining beyond the
        // heading; only a double tap containing the bound tap does.
        NSString *shared = entry.startsWithBoundTap
            ? [motion stringByAppendingString:@", which opens with your single tap"]
            : motion;
        NSString *bullet = entry.setting != NULL
            ? [NSString stringWithFormat:@"%s\n    macOS: %@", entry.setting, shared]
            : [NSString stringWithFormat:@"macOS: %@", shared];
        NSMutableSet *seenSlugs = [NSMutableSet set];
        for (NSString *slug in [[NSString stringWithUTF8String:entry.slugs]
                                componentsSeparatedByString:@","]) {
            if (![configured containsObject:slug] || [seenSlugs containsObject:slug])
                continue;
            [seenSlugs addObject:slug];
            NSString *binding = [NSString stringWithFormat:@"%@ %@", device, slug];
            if ([bulletsByBinding objectForKey:binding] == nil) {
                [order addObject:binding];
                [bulletsByBinding setObject:[NSMutableArray array] forKey:binding];
            }
            [[bulletsByBinding objectForKey:binding] addObject:
                [NSString stringWithFormat:@"  • %@\n    Change it in System Settings > %s",
                 bullet, entry.location]];
        }
    }

    NSMutableArray *warnings = [NSMutableArray array];
    for (NSString *binding in order) {
        [warnings addObject:[NSString stringWithFormat:
            @"Your %@ binding shares its motion with:\n%@", binding,
            [[bulletsByBinding objectForKey:binding] componentsJoinedByString:@"\n"]]];
    }
    return warnings;
}

NSArray *MGSystemGestureClaimTableLines(void) {
    NSMutableArray *lines = [NSMutableArray array];
    for (size_t i = 0; i < kEntryCount; i++) {
        const MGSystemGestureEntry entry = kEntries[i];
        for (NSString *slug in [[NSString stringWithUTF8String:entry.slugs]
                                componentsSeparatedByString:@","]) {
            [lines addObject:[NSString stringWithFormat:@"%@ %s %s %@",
                              entry.trackpad ? @"trackpad" : @"mouse",
                              entry.domains, entry.key, slug]];
        }
    }
    return [lines sortedArrayUsingSelector:@selector(compare:)];
}

// Raise this after reading the panes named in kEntries on a newer release and
// correcting anything Apple moved. Preference keys outlive interface labels, so
// a stale value here costs a reader an extra look, not a wrong warning.
static const NSInteger kSettingsVerifiedMacOSMajor = 26;

NSString *MGSystemGestureSettingsProvenance(void) {
    NSInteger running = [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion;
    NSString *checked = [NSString stringWithFormat:
        @"Setting names and locations were last checked on macOS %ld.",
        (long)kSettingsVerifiedMacOSMajor];
    if (running <= kSettingsVerifiedMacOSMajor)
        return checked;
    return [checked stringByAppendingFormat:
        @" This Mac runs macOS %ld, so a name may have moved.", (long)running];
}

NSArray *MGSystemGestureConflictsForCurrentUser(NSSet *configuredMouseSlugs,
                                                NSSet *configuredTrackpadSlugs) {
    return MGSystemGestureConflicts(configuredMouseSlugs, configuredTrackpadSlugs,
        ^NSNumber *(NSString *domains, NSString *key) {
            for (NSString *domain in [domains componentsSeparatedByString:@","]) {
                id value = [(id)CFPreferencesCopyAppValue((CFStringRef)key,
                                                          (CFStringRef)domain) autorelease];
                if ([value isKindOfClass:[NSNumber class]])
                    return value;
            }
            return nil;
        });
}
