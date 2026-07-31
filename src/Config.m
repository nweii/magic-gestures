//
//  Config.m
//  MagicGestures
//
//  Copyright 2026 Nathan Cheng. All rights reserved.
//

#import "Config.h"
#import <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>

// The tables below accept several spellings for each value. Both people and
// agents write this file, and they do not converge on one spelling.

@implementation Config

#pragma mark - Gesture vocabulary

// Configuration slugs mapped to the engine's gesture names. The engine
// distinguishes how far apart two fingers land; a slug binding several names
// covers a split the hand does not make.
+ (NSDictionary *)mouseGestureSlugs {
    static NSDictionary *m = nil;
    if (m == nil) {
        m = [@{
            @"hold-index-tap-middle": @[@"Index-Fix Middle-Near-Tap", @"Index-Fix Middle-Far-Tap"],
            @"hold-middle-tap-index": @[@"Middle-Fix Index-Near-Tap", @"Middle-Fix Index-Far-Tap"],
            @"hold-index-slide-middle": @[@"Index-Fix Middle-Slide-In", @"Index-Fix Middle-Slide-Out"],
            @"hold-middle-slide-index": @[@"Middle-Fix Index-Slide-In", @"Middle-Fix Index-Slide-Out"],
            @"one-finger-tap": @[@"One-Finger Tap"],
            @"two-finger-tap": @[@"Two-Finger Tap"],
            @"three-finger-tap": @[@"Three-Finger Tap"],
            @"front-right-tap": @[@"Right-Front Tap"],
            @"one-finger-swipe-left": @[@"One-Swipe-Left"],
            @"one-finger-swipe-right": @[@"One-Swipe-Right"],
            @"two-finger-swipe-left": @[@"Two-Swipe-Left"],
            @"two-finger-swipe-right": @[@"Two-Swipe-Right"],
            @"three-finger-swipe-left": @[@"Three-Swipe-Left"],
            @"three-finger-swipe-right": @[@"Three-Swipe-Right"],
            @"three-finger-swipe-up": @[@"Three-Swipe-Up"],
            @"three-finger-swipe-down": @[@"Three-Swipe-Down"],
        } retain];
    }
    return m;
}

+ (NSDictionary *)trackpadGestureSlugs {
    static NSDictionary *m = nil;
    if (m == nil) {
        m = [@{
            @"hold-tap-left": @[@"One-Fix Left-Tap"],
            @"hold-tap-right": @[@"One-Fix Right-Tap"],
            @"hold-slide": @[@"One-Fix One-Slide"],
            @"two-finger-tap": @[@"Two-Finger Tap"],
            @"three-finger-tap": @[@"Three-Finger Tap"],
            @"four-finger-tap": @[@"Four-Finger Tap"],
            @"three-finger-swipe-left": @[@"Three-Swipe-Left"],
            @"three-finger-swipe-right": @[@"Three-Swipe-Right"],
            @"three-finger-swipe-up": @[@"Three-Swipe-Up"],
            @"three-finger-swipe-down": @[@"Three-Swipe-Down"],
            @"four-finger-swipe-left": @[@"Four-Swipe-Left"],
            @"four-finger-swipe-right": @[@"Four-Swipe-Right"],
            @"four-finger-swipe-up": @[@"Four-Swipe-Up"],
            @"four-finger-swipe-down": @[@"Four-Swipe-Down"],
            @"index-to-pinky": @[@"Index-To-Pinky"],
            @"pinky-to-index": @[@"Pinky-To-Index"],
        } retain];
    }
    return m;
}

// Built-in engine commands, keyed by the slug the configuration uses. The value
// is the exact string dispatchCommand compares against in Gesture.m.
static NSDictionary *actionNames(void) {
    static NSDictionary *m = nil;
    if (m == nil) {
        m = [@{
            @"middle-click": @"Middle Click",
            @"mission-control": @"Mission Control",
            @"move-resize": @"Move / Resize",
            @"next-tab": @"Next Tab",
            @"previous-tab": @"Previous Tab",
            @"new-tab": @"New Tab",
            @"close-tab": @"Close / Close Tab",
            @"reopen-tab": @"Open Recently Closed Tab",
            @"maximize": @"Maximize",
            @"minimize": @"Minimize",
        } retain];
    }
    return m;
}

#pragma mark - Keystroke vocabulary

static NSDictionary *keyNames(void) {
    static NSDictionary *m = nil;
    if (m == nil) {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        NSDictionary *named = @{
            @"return": @36, @"enter": @36,
            @"escape": @53, @"esc": @53,
            @"tab": @48,
            @"space": @49, @"spacebar": @49,
            @"delete": @51, @"backspace": @51, @"del": @51,
            @"forward-delete": @117,
            @"keypad-enter": @76,
            @"left": @123, @"right": @124, @"down": @125, @"up": @126,
            @"home": @115, @"end": @119,
            @"page-up": @116, @"page-down": @121,
            @"f1": @122, @"f2": @120, @"f3": @99, @"f4": @118,
            @"f5": @96, @"f6": @97, @"f7": @98, @"f8": @100,
            @"f9": @101, @"f10": @109, @"f11": @103, @"f12": @111,
            @"[": @33, @"]": @30, @"-": @27, @"=": @24,
            @";": @41, @"'": @39, @",": @43, @".": @47, @"/": @44,
            @"\\": @42, @"`": @50,
        };
        [d addEntriesFromDictionary:named];

        // Letters and digits, so the tables above stay short.
        NSString *letters = @"asdfhgzxcv bqweryt123465=97-80]ou[ip lj'k;\\,/nm.";
        const int letterCodes[] = {0,1,2,3,4,5,6,7,8,9,-1,11,12,13,14,15,16,17,
                                   18,19,20,21,23,22,24,25,26,27,28,29,30,31,32,
                                   33,34,35,-1,37,38,39,40,41,42,43,44,45,46,47};
        for (NSUInteger i = 0; i < [letters length] && i < sizeof(letterCodes)/sizeof(int); i++) {
            if (letterCodes[i] < 0)
                continue;
            NSString *ch = [letters substringWithRange:NSMakeRange(i, 1)];
            if ([d objectForKey:ch] == nil)
                [d setObject:@(letterCodes[i]) forKey:ch];
        }
        m = d;
    }
    return m;
}

// Modifier spellings, all lowercase. The symbols are here so a value copied out
// of a keyboard shortcut reference parses without being retyped.
static NSDictionary *modifierNames(void) {
    static NSDictionary *m = nil;
    if (m == nil) {
        m = [@{
            @"cmd": @(kCGEventFlagMaskCommand), @"command": @(kCGEventFlagMaskCommand), @"⌘": @(kCGEventFlagMaskCommand),
            @"ctrl": @(kCGEventFlagMaskControl), @"control": @(kCGEventFlagMaskControl), @"⌃": @(kCGEventFlagMaskControl),
            @"opt": @(kCGEventFlagMaskAlternate), @"option": @(kCGEventFlagMaskAlternate),
            @"alt": @(kCGEventFlagMaskAlternate), @"⌥": @(kCGEventFlagMaskAlternate),
            @"shift": @(kCGEventFlagMaskShift), @"⇧": @(kCGEventFlagMaskShift),
        } retain];
    }
    return m;
}

#pragma mark - Value parsing

static NSString *stripQuotes(NSString *s) {
    if ([s length] >= 2) {
        unichar first = [s characterAtIndex:0];
        unichar last = [s characterAtIndex:[s length] - 1];
        if ((first == '"' && last == '"') || (first == '\'' && last == '\''))
            return [s substringWithRange:NSMakeRange(1, [s length] - 2)];
    }
    return s;
}

static BOOL parseBoolean(NSString *v, BOOL fallback) {
    NSString *s = [[stripQuotes(v) lowercaseString] stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceCharacterSet]];
    if ([@[@"true", @"yes", @"on", @"1"] containsObject:s]) return YES;
    if ([@[@"false", @"no", @"off", @"0"] containsObject:s]) return NO;
    return fallback;
}

// Returns a gesture dictionary in the engine's shape, or nil when the value
// names nothing recognizable. A keystroke is modifiers plus one key; anything
// matching an action name is dispatched by name instead.
static NSDictionary *parseBinding(NSString *rawValue) {
    NSString *value = [stripQuotes([rawValue stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceCharacterSet]]) lowercaseString];
    if ([value length] == 0)
        return nil;

    NSString *action = [actionNames() objectForKey:value];
    if (action != nil) {
        return @{@"Gesture": @"", @"Command": action, @"IsAction": @YES,
                 @"ModifierFlags": @0, @"KeyCode": @0, @"Enable": @YES};
    }

    NSUInteger flags = 0;

    // Leading symbol modifiers carry no separator, so consume them first.
    while ([value length] > 0) {
        NSString *head = [value substringToIndex:1];
        NSNumber *flag = [modifierNames() objectForKey:head];
        if (flag == nil)
            break;
        flags |= [flag unsignedIntegerValue];
        value = [value substringFromIndex:1];
    }

    NSArray *tokens = nil;
    if ([keyNames() objectForKey:value] != nil) {
        // A whole-value match wins before splitting, so page-down and
        // forward-delete are not torn apart by the hyphen separator.
        tokens = @[value];
    } else {
        tokens = [value componentsSeparatedByString:@"+"];
        if ([tokens count] == 1) {
            NSMutableCharacterSet *seps = [NSMutableCharacterSet whitespaceCharacterSet];
            [seps addCharactersInString:@"-"];
            tokens = [value componentsSeparatedByCharactersInSet:seps];
        }
    }

    NSString *keyToken = nil;
    for (NSString *raw in tokens) {
        NSString *t = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([t length] == 0)
            continue;
        NSNumber *flag = [modifierNames() objectForKey:t];
        if (flag != nil) {
            flags |= [flag unsignedIntegerValue];
            continue;
        }
        keyToken = t;
    }

    if (keyToken == nil)
        return nil;
    NSNumber *code = [keyNames() objectForKey:keyToken];
    if (code == nil)
        return nil;

    return @{@"Gesture": @"", @"Command": rawValue, @"IsAction": @NO,
             @"ModifierFlags": @(flags), @"KeyCode": code, @"Enable": @YES};
}

#pragma mark - File loading

+ (NSString *)resolvedPath {
    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    if ([bundlePath length] > 0) {
        NSString *root = [[bundlePath stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
        NSString *inRepo = [[root stringByAppendingPathComponent:@"config.txt"] stringByStandardizingPath];
        // `config` is the file; the older layout used a directory of the same
        // name, so make sure this is not that.
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:inRepo isDirectory:&isDir] && !isDir)
            return inRepo;
    }

    NSString *user = [@"~/.config/magic-gestures/config.txt" stringByStandardizingPath];
    if ([fm fileExistsAtPath:user])
        return user;

    return nil;
}

+ (NSDictionary *)settingsFromFile:(NSString *)path {
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    if (text == nil)
        return nil;

    NSMutableArray *mouse = [NSMutableArray array];
    NSMutableArray *trackpad = [NSMutableArray array];
    NSMutableDictionary *general = [NSMutableDictionary dictionary];
    NSString *section = @"general";

    for (NSString *rawLine in [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        NSString *line = rawLine;
        NSRange hash = [line rangeOfString:@"#"];
        if (hash.location != NSNotFound)
            line = [line substringToIndex:hash.location];
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([line length] == 0)
            continue;

        if ([line hasPrefix:@"["] && [line hasSuffix:@"]"]) {
            section = [[line substringWithRange:NSMakeRange(1, [line length] - 2)]
                       stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            section = [section lowercaseString];
            continue;
        }

        NSRange eq = [line rangeOfString:@"="];
        if (eq.location == NSNotFound)
            continue;
        NSString *key = [[line substringToIndex:eq.location]
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *value = [[line substringFromIndex:eq.location + 1]
                           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        key = [key lowercaseString];

        // An inline device name overrides the section, so a line appended to
        // the end of the file cannot be misfiled by whatever preceded it.
        NSString *device = section;
        NSRange dot = [key rangeOfString:@"."];
        if (dot.location != NSNotFound) {
            device = [key substringToIndex:dot.location];
            key = [key substringFromIndex:dot.location + 1];
        }

        if ([device isEqualToString:@"mouse"] || [device isEqualToString:@"trackpad"]) {
            NSDictionary *slugs = [device isEqualToString:@"mouse"]
                ? [Config mouseGestureSlugs] : [Config trackpadGestureSlugs];
            NSArray *engineNames = [slugs objectForKey:key];
            NSDictionary *binding = parseBinding(value);
            if (engineNames == nil || binding == nil)
                continue;

            NSMutableArray *target = [device isEqualToString:@"mouse"] ? mouse : trackpad;
            for (NSString *name in engineNames) {
                NSMutableDictionary *g = [[binding mutableCopy] autorelease];
                [g setObject:name forKey:@"Gesture"];
                [target addObject:g];
            }
        } else {
            [general setObject:value forKey:key];
        }
    }

    NSString *(^str)(NSString *, NSString *) = ^(NSString *k, NSString *fallback) {
        NSString *v = [general objectForKey:k];
        return v ?: fallback;
    };

    return @{
        @"enAll": @1,
        @"ClickSpeed": @([str(@"tap-speed", @"0.25") floatValue]),
        @"Sensitivity": @4.6666,
        @"ShowIcon": @(parseBoolean(str(@"show-menu-bar-icon", @"true"), YES) ? 1 : 0),
        @"LogLevel": @(parseBoolean(str(@"verbose-logging", @"false"), NO) ? 2 : 1),
        @"enTPAll": @(parseBoolean(str(@"enable-trackpad", @"true"), YES) ? 1 : 0),
        @"enMMAll": @(parseBoolean(str(@"enable-mouse", @"true"), YES) ? 1 : 0),
        @"Handed": @0,
        @"MMHanded": @0,
        @"enCharRegTP": @0,
        @"enCharRegMM": @0,
        @"charRegMouseButton": @0,
        @"charRegIndexRingDistance": @0.33,
        @"enOneDrawing": @0,
        @"enTwoDrawing": @1,
        @"TrackpadCommands": @[@{@"Application": @"All Applications", @"Path": @"", @"Gestures": trackpad}],
        @"MagicMouseCommands": @[@{@"Application": @"All Applications", @"Path": @"", @"Gestures": mouse}],
        @"RecognitionCommands": @[@{@"Application": @"All Applications", @"Path": @"", @"Gestures": @[]}],
    };
}

@end
