//
//  Config.m
//  MagicGestures
//
//  Copyright 2026 Nathan Cheng. All rights reserved.
//

#import "Config.h"
#import <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>
#import <IOKit/hidsystem/IOLLEvent.h>
#import <math.h>

// The tables accept common alternative spellings because people and coding
// agents may use different names for the same value.

@implementation Config

#pragma mark - Gesture vocabulary

// Configuration slugs map to the engine's gesture names. One slug may cover
// several engine names that differ only by the distance between two fingers.
+ (NSDictionary *)mouseGestureSlugs {
    static NSDictionary *m = nil;
    if (m == nil) {
        m = [@{
            @"hold-left-tap-right": @[@"Index-Fix Middle-Near-Tap", @"Index-Fix Middle-Far-Tap"],
            @"hold-right-tap-left": @[@"Middle-Fix Index-Near-Tap", @"Middle-Fix Index-Far-Tap"],
            @"hold-left-slide-right": @[@"Index-Fix Middle-Slide-In", @"Index-Fix Middle-Slide-Out"],
            @"hold-right-slide-left": @[@"Middle-Fix Index-Slide-In", @"Middle-Fix Index-Slide-Out"],
            @"one-finger-tap": @[@"One-Finger Tap"],
            @"two-finger-tap": @[@"Two-Finger Tap"],
            @"three-finger-tap": @[@"Three-Finger Tap"],
            @"two-finger-click": @[@"Two-Finger Click"],
            @"three-finger-click": @[@"Three-Finger Click"],
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
            @"hold-right-tap-left": @[@"One-Fix Left-Tap"],
            @"hold-left-tap-right": @[@"One-Fix Right-Tap"],
            @"hold-slide": @[@"One-Fix One-Slide"],
            @"two-finger-tap": @[@"Two-Finger Tap"],
            @"three-finger-tap": @[@"Three-Finger Tap"],
            @"four-finger-tap": @[@"Four-Finger Tap"],
            @"five-finger-tap": @[@"Five-Finger Tap"],
            @"three-finger-click": @[@"Three-Finger Click"],
            @"four-finger-click": @[@"Four-Finger Click"],
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

+ (NSString *)canonicalGestureName:(NSString *)raw inSlugs:(NSDictionary *)slugs {
    for (NSString *slug in slugs) {
        NSArray *engineNames = [slugs objectForKey:slug];
        if ([engineNames containsObject:raw])
            return [engineNames firstObject];
    }
    return raw;
}

// Built-in engine commands, keyed by the slug the configuration uses. The value
// is the exact string dispatchCommand compares against in Gesture.m.
+ (NSDictionary *)actionNames {
    static NSDictionary *m = nil;
    if (m == nil) {
        m = [@{
            @"middle-click": @"Middle Click",
            @"mission-control": @"Mission Control",
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

// Engine gesture names phrased as the motion a hand makes, for the menu. Every
// name reachable from a slug table needs an entry; scripts/check.sh enforces it.
+ (NSString *)humanNameForGesture:(NSString *)raw {
    static NSDictionary *phrases = nil;
    if (phrases == nil) {
        phrases = [@{
            @"Index-Fix Middle-Near-Tap": @"Hold your left finger, tap to its right",
            @"Index-Fix Middle-Far-Tap": @"Hold your left finger, tap wide to its right",
            @"Middle-Fix Index-Near-Tap": @"Hold your right finger, tap to its left",
            @"Middle-Fix Index-Far-Tap": @"Hold your right finger, tap wide to its left",
            @"One-Fix Left-Tap": @"Hold your right finger, tap to its left",
            @"One-Fix Right-Tap": @"Hold your left finger, tap to its right",
            @"One-Fix One-Slide": @"Hold one finger, slide another",
            @"One-Finger Tap": @"Tap with one finger",
            @"Two-Finger Tap": @"Tap with two fingers",
            @"Three-Finger Tap": @"Tap with three fingers",
            @"Four-Finger Tap": @"Tap with four fingers",
            @"Five-Finger Tap": @"Tap with five fingers",
            @"Two-Finger Click": @"Click with two fingers",
            @"Three-Finger Click": @"Click with three fingers",
            @"Four-Finger Click": @"Click with four fingers",
            @"Right-Front Tap": @"Tap the front right of the mouse",
            @"One-Swipe-Left": @"Swipe left with one finger",
            @"One-Swipe-Right": @"Swipe right with one finger",
            @"Two-Swipe-Left": @"Swipe left with two fingers",
            @"Two-Swipe-Right": @"Swipe right with two fingers",
            @"Three-Swipe-Left": @"Swipe left with three fingers",
            @"Three-Swipe-Right": @"Swipe right with three fingers",
            @"Three-Swipe-Up": @"Swipe up with three fingers",
            @"Three-Swipe-Down": @"Swipe down with three fingers",
            @"Four-Swipe-Left": @"Swipe left with four fingers",
            @"Four-Swipe-Right": @"Swipe right with four fingers",
            @"Four-Swipe-Up": @"Swipe up with four fingers",
            @"Four-Swipe-Down": @"Swipe down with four fingers",
            @"Index-Fix Middle-Slide-In": @"Hold your left finger, slide the right one inward",
            @"Index-Fix Middle-Slide-Out": @"Hold your left finger, slide the right one outward",
            @"Middle-Fix Index-Slide-In": @"Hold your right finger, slide the left one inward",
            @"Middle-Fix Index-Slide-Out": @"Hold your right finger, slide the left one outward",
            @"Index-To-Pinky": @"Brush index toward pinky",
            @"Pinky-To-Index": @"Brush pinky toward index",
        } retain];
    }
    NSString *phrase = [phrases objectForKey:raw];
    return phrase ?: raw;
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

        // Letters and digits are derived directly instead of listed in the tables.
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

// Modifier spellings are lowercase. Symbols allow copied keyboard shortcuts to
// parse without replacing the symbols with names.
static NSDictionary *modifierNames(void) {
    static NSDictionary *m = nil;
    if (m == nil) {
        m = [@{
            @"cmd": @(kCGEventFlagMaskCommand | NX_DEVICELCMDKEYMASK),
            @"command": @(kCGEventFlagMaskCommand | NX_DEVICELCMDKEYMASK),
            @"⌘": @(kCGEventFlagMaskCommand | NX_DEVICELCMDKEYMASK),
            @"left-cmd": @(kCGEventFlagMaskCommand | NX_DEVICELCMDKEYMASK),
            @"left-command": @(kCGEventFlagMaskCommand | NX_DEVICELCMDKEYMASK),
            @"right-cmd": @(kCGEventFlagMaskCommand | NX_DEVICERCMDKEYMASK),
            @"right-command": @(kCGEventFlagMaskCommand | NX_DEVICERCMDKEYMASK),
            @"ctrl": @(kCGEventFlagMaskControl | NX_DEVICELCTLKEYMASK),
            @"control": @(kCGEventFlagMaskControl | NX_DEVICELCTLKEYMASK),
            @"⌃": @(kCGEventFlagMaskControl | NX_DEVICELCTLKEYMASK),
            @"left-ctrl": @(kCGEventFlagMaskControl | NX_DEVICELCTLKEYMASK),
            @"left-control": @(kCGEventFlagMaskControl | NX_DEVICELCTLKEYMASK),
            @"right-ctrl": @(kCGEventFlagMaskControl | NX_DEVICERCTLKEYMASK),
            @"right-control": @(kCGEventFlagMaskControl | NX_DEVICERCTLKEYMASK),
            @"opt": @(kCGEventFlagMaskAlternate | NX_DEVICELALTKEYMASK),
            @"option": @(kCGEventFlagMaskAlternate | NX_DEVICELALTKEYMASK),
            @"alt": @(kCGEventFlagMaskAlternate | NX_DEVICELALTKEYMASK),
            @"⌥": @(kCGEventFlagMaskAlternate | NX_DEVICELALTKEYMASK),
            @"left-opt": @(kCGEventFlagMaskAlternate | NX_DEVICELALTKEYMASK),
            @"left-option": @(kCGEventFlagMaskAlternate | NX_DEVICELALTKEYMASK),
            @"left-alt": @(kCGEventFlagMaskAlternate | NX_DEVICELALTKEYMASK),
            @"right-opt": @(kCGEventFlagMaskAlternate | NX_DEVICERALTKEYMASK),
            @"right-option": @(kCGEventFlagMaskAlternate | NX_DEVICERALTKEYMASK),
            @"right-alt": @(kCGEventFlagMaskAlternate | NX_DEVICERALTKEYMASK),
            @"shift": @(kCGEventFlagMaskShift | NX_DEVICELSHIFTKEYMASK),
            @"⇧": @(kCGEventFlagMaskShift | NX_DEVICELSHIFTKEYMASK),
            @"left-shift": @(kCGEventFlagMaskShift | NX_DEVICELSHIFTKEYMASK),
            @"right-shift": @(kCGEventFlagMaskShift | NX_DEVICERSHIFTKEYMASK),
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

static BOOL parseBooleanValue(NSString *v, BOOL *result) {
    NSString *s = [[stripQuotes(v) lowercaseString] stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceCharacterSet]];
    if ([@[@"true", @"yes", @"on", @"1"] containsObject:s]) {
        if (result) *result = YES;
        return YES;
    }
    if ([@[@"false", @"no", @"off", @"0"] containsObject:s]) {
        if (result) *result = NO;
        return YES;
    }
    return NO;
}

static BOOL parseBoolean(NSString *v, BOOL fallback) {
    BOOL result = fallback;
    parseBooleanValue(v, &result);
    return result;
}

static BOOL parsePositiveNumber(NSString *v, double *result) {
    NSString *s = [stripQuotes(v) stringByTrimmingCharactersInSet:
                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSScanner *scanner = [NSScanner scannerWithString:s];
    double number = 0;
    if (![scanner scanDouble:&number] || ![scanner isAtEnd] || !isfinite(number) || number <= 0)
        return NO;
    if (result) *result = number;
    return YES;
}

// Returns why a custom URL cannot be opened, or nil when its structure is
// valid. Handler availability is deliberately left to macOS at dispatch time.
static NSString *urlProblem(NSString *value) {
    if ([value length] == 0)
        return @"URL is empty";

    if ([value rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound)
        return @"URL contains unencoded whitespace";

    NSRange colon = [value rangeOfString:@":"];
    if (colon.location == NSNotFound || colon.location == 0)
        return @"URL is missing a valid scheme followed by \":\"";

    NSString *scheme = [value substringToIndex:colon.location];
    NSCharacterSet *first = [NSCharacterSet characterSetWithCharactersInString:
                             @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    if (![first characterIsMember:[scheme characterAtIndex:0]])
        return @"URL scheme must begin with a letter";

    NSMutableCharacterSet *schemeCharacters = [NSMutableCharacterSet characterSetWithCharactersInString:
                                                @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+.-"];
    if ([scheme rangeOfCharacterFromSet:[schemeCharacters invertedSet]].location != NSNotFound)
        return @"URL scheme may contain only letters, digits, +, -, and .";

    NSCharacterSet *hex = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
    for (NSUInteger i = 0; i < [value length]; i++) {
        if ([value characterAtIndex:i] != '%')
            continue;
        if (i + 2 >= [value length] ||
            ![hex characterIsMember:[value characterAtIndex:i + 1]] ||
            ![hex characterIsMember:[value characterAtIndex:i + 2]])
            return @"URL contains a malformed percent escape";
        i += 2;
    }

    if ([NSURL URLWithString:value] == nil)
        return @"URL could not be parsed";
    return nil;
}

static BOOL dateFormatHasBalancedQuotes(NSString *format) {
    BOOL quoted = NO;
    for (NSUInteger i = 0; i < [format length]; i++) {
        if ([format characterAtIndex:i] != '\'')
            continue;
        if (i + 1 < [format length] && [format characterAtIndex:i + 1] == '\'') {
            i++;
            continue;
        }
        quoted = !quoted;
    }
    return !quoted;
}

// Returns why a substitution expression is invalid, or nil for one of the
// three expressions the configuration language supports.
static NSString *substitutionProblem(NSString *expression) {
    if ([expression isEqualToString:@"clipboard"] ||
        [expression isEqualToString:@"clipboard|urlencode"])
        return nil;

    if ([expression hasPrefix:@"datetime:"]) {
        NSString *format = [expression substringFromIndex:9];
        if ([format length] == 0)
            return @"datetime substitution needs a format";
        if (!dateFormatHasBalancedQuotes(format))
            return @"datetime substitution has an unmatched quote";
        return nil;
    }

    if ([expression hasPrefix:@"clipboard|"])
        return [NSString stringWithFormat:@"unknown clipboard substitution filter \"%@\"",
                [expression substringFromIndex:10]];

    return [NSString stringWithFormat:@"unknown substitution \"%@\"", expression];
}

// Encodes one URL component using only RFC 3986 unreserved bytes. In
// particular, &, =, /, and ? are escaped rather than changing URL structure.
static NSString *encodeURLComponent(NSString *value) {
    NSCharacterSet *unreserved = [NSCharacterSet characterSetWithCharactersInString:
                                  @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"];
    return [(value ?: @"") stringByAddingPercentEncodingWithAllowedCharacters:unreserved];
}

+ (NSString *)URLByResolvingSubstitutions:(NSString *)url
                                clipboard:(NSString *)clipboard
                                     date:(NSDate *)date
                                  problem:(NSString **)outProblem {
    if (outProblem != NULL)
        *outProblem = nil;

    NSMutableString *resolved = [NSMutableString string];
    NSUInteger cursor = 0;
    while (cursor < [url length]) {
        unichar c = [url characterAtIndex:cursor];
        if (c != '{' && c != '}') {
            [resolved appendFormat:@"%C", c];
            cursor++;
            continue;
        }

        if (c == '}' || cursor + 1 >= [url length] || [url characterAtIndex:cursor + 1] != '{') {
            if (outProblem != NULL)
                *outProblem = @"substitution has unmatched braces";
            return nil;
        }

        NSRange close = [url rangeOfString:@"}}"
                                    options:0
                                      range:NSMakeRange(cursor + 2, [url length] - cursor - 2)];
        if (close.location == NSNotFound) {
            if (outProblem != NULL)
                *outProblem = @"substitution has unmatched braces";
            return nil;
        }

        NSString *expression = [url substringWithRange:NSMakeRange(cursor + 2,
                                              close.location - cursor - 2)];
        if ([expression rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]].location != NSNotFound) {
            if (outProblem != NULL)
                *outProblem = @"substitution has unmatched braces";
            return nil;
        }

        NSString *problem = substitutionProblem(expression);
        if (problem != nil) {
            if (outProblem != NULL)
                *outProblem = problem;
            return nil;
        }

        if ([expression isEqualToString:@"clipboard"])
            [resolved appendString:clipboard ?: @""];
        else if ([expression isEqualToString:@"clipboard|urlencode"])
            [resolved appendString:encodeURLComponent(clipboard)];
        else {
            NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
            [formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
            [formatter setTimeZone:[NSTimeZone localTimeZone]];
            [formatter setDateFormat:[expression substringFromIndex:9]];
            [resolved appendString:[formatter stringFromDate:date ?: [NSDate date]]];
        }
        cursor = close.location + 2;
    }

    NSString *problem = urlProblem(resolved);
    if (problem != nil) {
        if (outProblem != NULL)
            *outProblem = problem;
        return nil;
    }
    return resolved;
}

static NSString *urlBindingProblem(NSString *url) {
    NSString *problem = nil;
    [Config URLByResolvingSubstitutions:url
                             clipboard:@"clipboard"
                                  date:[NSDate dateWithTimeIntervalSince1970:0]
                               problem:&problem];
    return problem;
}

// Resolves one directly executable file. Scripts run through their shebang;
// accepting shell source here would add a second configuration language.
static NSString *resolvedScriptPath(NSString *rawPath, NSString **outProblem) {
    NSString *path = [[rawPath stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceCharacterSet]] stringByExpandingTildeInPath];
    path = [path stringByStandardizingPath];
    NSString *problem = nil;
    if ([path length] == 0)
        problem = @"script path is empty";
    else if (![path isAbsolutePath])
        problem = @"script must use an absolute path or begin with ~";
    else {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
        if (attributes == nil)
            problem = @"script file does not exist";
        else if (![[attributes objectForKey:NSFileType] isEqualToString:NSFileTypeRegular])
            problem = @"script path is not a regular file";
        else if (![[NSFileManager defaultManager] isExecutableFileAtPath:path])
            problem = @"script file is not executable";
    }
    if (outProblem != NULL)
        *outProblem = problem;
    return problem == nil ? path : nil;
}

// Returns an engine gesture dictionary, or nil for an unrecognized value.
// Keystrokes contain modifiers and one key. Actions are dispatched by name.
static NSDictionary *parseBinding(NSString *rawValue) {
    NSString *unquoted = stripQuotes([rawValue stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]]);
    NSString *value = [unquoted lowercaseString];
    if ([value length] == 0)
        return nil;

    if ([value isEqualToString:@"off"])
        return @{ @"Gesture": @"", @"Command": @"", @"IsAction": @YES,
                  @"ModifierFlags": @0, @"KeyCode": @0, @"Enable": @NO };

    if ([value hasPrefix:@"url:"]) {
        NSString *url = [unquoted substringFromIndex:4];
        if (urlBindingProblem(url) != nil)
            return nil;
        return @{ @"Gesture": @"", @"Command": url, @"OpenURL": url,
                  @"IsAction": @YES, @"ModifierFlags": @0, @"KeyCode": @0,
                  @"Enable": @YES };
    }

    if ([value hasPrefix:@"script:"]) {
        NSString *path = resolvedScriptPath([unquoted substringFromIndex:7], NULL);
        if (path == nil)
            return nil;
        return @{ @"Gesture": @"", @"Command": path, @"ScriptPath": path,
                  @"IsAction": @YES, @"ModifierFlags": @0, @"KeyCode": @0,
                  @"Enable": @YES };
    }

    NSString *action = [[Config actionNames] objectForKey:value];
    if (action != nil) {
        return @{@"Gesture": @"", @"Command": action, @"IsAction": @YES,
                 @"ModifierFlags": @0, @"KeyCode": @0, @"Enable": @YES};
    }

    NSUInteger flags = 0;

    // Leading modifier symbols have no separator and must be consumed first.
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
        // Match the full value before splitting so the hyphens in page-down and
        // forward-delete are treated as part of the key name.
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
    for (NSUInteger i = 0; i < [tokens count]; i++) {
        NSString *raw = [tokens objectAtIndex:i];
        NSString *t = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([t length] == 0)
            continue;
        NSNumber *flag = [modifierNames() objectForKey:t];
        if (flag == nil && ([t isEqualToString:@"left"] || [t isEqualToString:@"right"]) &&
            i + 1 < [tokens count]) {
            NSString *next = [[tokens objectAtIndex:i + 1]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *sidedModifier = [NSString stringWithFormat:@"%@-%@", t, next];
            flag = [modifierNames() objectForKey:sidedModifier];
            if (flag != nil)
                i++;
        }
        if (flag != nil) {
            flags |= [flag unsignedIntegerValue];
            continue;
        }
        // A value carries exactly one key. An unknown token, or a second key,
        // rejects the whole value instead of binding a different shortcut.
        if (keyToken != nil || [keyNames() objectForKey:t] == nil)
            return nil;
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
    NSString *override = [[[NSProcessInfo processInfo] environment] objectForKey:@"MAGICGESTURES_CONFIG"];
    if ([override length] > 0)
        return [override stringByStandardizingPath];

    NSString *path = [[self configDirectory] stringByAppendingPathComponent:@"config.txt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        return path;
    return nil;
}

+ (NSString *)configDirectory {
    return [@"~/.config/magic-gestures" stringByStandardizingPath];
}

// Setting names accepted in [general]. A name outside this set is reported
// rather than ignored, which catches a misspelling that would otherwise leave
// the default in place with no sign anything was wrong.
static NSSet *knownSettingNames(void) {
    static NSSet *s = nil;
    if (s == nil) {
        s = [[NSSet setWithArray:@[@"config-version", @"dominant-hand", @"enable-mouse", @"enable-trackpad", @"tap-speed",
                                   @"haptic-feedback", @"verbose-logging",
                                   @"experimental-mouse-click-gestures"]] retain];
    }
    return s;
}

static NSArray *splitExpandedProperties(NSString *body) {
    NSMutableArray *properties = [NSMutableArray array];
    NSUInteger start = 0;
    BOOL quoted = NO;
    BOOL escaped = NO;
    for (NSUInteger i = 0; i < [body length]; i++) {
        unichar character = [body characterAtIndex:i];
        if (character == '"' && !escaped)
            quoted = !quoted;
        if (character == ',' && !quoted) {
            [properties addObject:[body substringWithRange:NSMakeRange(start, i - start)]];
            start = i + 1;
        }
        escaped = character == '\\' && !escaped;
        if (character != '\\')
            escaped = NO;
    }
    [properties addObject:[body substringFromIndex:start]];
    return properties;
}

static NSUInteger unquotedClosingBraceLocation(NSString *text) {
    BOOL quoted = NO;
    BOOL escaped = NO;
    for (NSUInteger i = 0; i < [text length]; i++) {
        unichar character = [text characterAtIndex:i];
        if (character == '"' && !escaped)
            quoted = !quoted;
        if (character == '}' && !quoted)
            return i;
        escaped = character == '\\' && !escaped;
        if (character != '\\')
            escaped = NO;
    }
    return NSNotFound;
}

+ (NSDictionary *)settingsFromFile:(NSString *)path {
    return [Config settingsFromFile:path problems:NULL];
}

+ (NSDictionary *)settingsFromFile:(NSString *)path problems:(NSArray **)outProblems {
    NSMutableArray *problems = [NSMutableArray array];
    if (outProblems != NULL)
        *outProblems = problems;

    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    if (text == nil)
        return nil;

    NSMutableArray *mouse = [NSMutableArray array];
    NSMutableArray *trackpad = [NSMutableArray array];
    NSMutableDictionary *mouseScopes = [NSMutableDictionary dictionaryWithObject:mouse
                                                                           forKey:@"All Applications"];
    NSMutableDictionary *trackpadScopes = [NSMutableDictionary dictionaryWithObject:trackpad
                                                                              forKey:@"All Applications"];
    NSMutableArray *mouseScopeOrder = [NSMutableArray arrayWithObject:@"All Applications"];
    NSMutableArray *trackpadScopeOrder = [NSMutableArray arrayWithObject:@"All Applications"];
    NSMutableDictionary *general = [NSMutableDictionary dictionary];
    NSString *section = @"general";
    NSString *application = nil;
    NSMutableSet *activeBindingKeys = [NSMutableSet set];
    __block NSInteger lineNumber = 0;
    NSInteger physicalLineNumber = 0;
    NSInteger pendingBlockLine = 0;
    NSMutableString *pendingBlock = nil;
    __block BOOL unsupportedVersion = NO;

    void (^report)(NSString *, NSString *) = ^(NSString *text, NSString *reason) {
        [problems addObject:[NSString stringWithFormat:@"line %ld:  %@\n          %@",
                             (long)lineNumber, text, reason]];
    };

    for (NSString *rawLine in [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        physicalLineNumber++;
        NSString *line = rawLine;
        // A comment begins at the start of a line or after whitespace. This
        // leaves URL fragments such as #section intact.
        for (NSUInteger i = 0; i < [line length]; i++) {
            if ([line characterAtIndex:i] != '#')
                continue;
            if (i == 0 || [[NSCharacterSet whitespaceCharacterSet]
                           characterIsMember:[line characterAtIndex:i - 1]]) {
                line = [line substringToIndex:i];
                break;
            }
        }
        line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([line length] == 0)
            continue;

        BOOL completedPendingBlock = NO;
        if (pendingBlock != nil) {
            NSRange pendingEquals = [line rangeOfString:@"="];
            NSString *pendingKey = pendingEquals.location == NSNotFound ? @"" :
                [[line substringToIndex:pendingEquals.location]
                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSRange pendingOpeningBrace = [line rangeOfString:@"{"];
            BOOL startsSection = [line hasPrefix:@"["];
            BOOL startsBinding = (pendingOpeningBrace.location != NSNotFound &&
                                  (pendingEquals.location == NSNotFound ||
                                   pendingOpeningBrace.location < pendingEquals.location)) ||
                (pendingEquals.location != NSNotFound &&
                 ![@[@"action", @"defer", @"haptic"] containsObject:[pendingKey lowercaseString]]);
            if (startsSection || startsBinding) {
                lineNumber = pendingBlockLine;
                report(pendingBlock, @"expanded binding is missing a closing }");
                pendingBlock = nil;
                lineNumber = physicalLineNumber;
            } else {
                [pendingBlock appendFormat:@"\n%@", line];
                if (unquotedClosingBraceLocation(pendingBlock) == NSNotFound)
                    continue;
                line = pendingBlock;
                lineNumber = pendingBlockLine;
                pendingBlock = nil;
                completedPendingBlock = YES;
            }
        }
        if (!completedPendingBlock) {
            lineNumber = physicalLineNumber;
            NSRange openingBrace = [line rangeOfString:@"{"];
            NSRange equals = [line rangeOfString:@"="];
            BOOL beginsBlock = openingBrace.location != NSNotFound &&
                (equals.location == NSNotFound || openingBrace.location < equals.location);
            if (beginsBlock && unquotedClosingBraceLocation(line) == NSNotFound) {
                pendingBlock = [NSMutableString stringWithString:line];
                pendingBlockLine = lineNumber;
                continue;
            }
        }

        if ([line hasPrefix:@"["] && [line hasSuffix:@"]"]) {
            NSString *header = [[line substringWithRange:NSMakeRange(1, [line length] - 2)]
                                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *lowerHeader = [header lowercaseString];
            application = nil;
            if ([lowerHeader isEqualToString:@"general"] ||
                [lowerHeader isEqualToString:@"mouse"] ||
                [lowerHeader isEqualToString:@"trackpad"]) {
                section = lowerHeader;
            } else {
                NSString *matchedDevice = nil;
                for (NSString *candidate in @[@"mouse", @"trackpad"]) {
                    if ([lowerHeader hasPrefix:[candidate stringByAppendingString:@" "]]) {
                        matchedDevice = candidate;
                        break;
                    }
                }
                NSString *selector = matchedDevice == nil ? nil :
                    [header substringFromIndex:[matchedDevice length]];
                selector = [selector stringByTrimmingCharactersInSet:
                            [NSCharacterSet whitespaceCharacterSet]];
                if (matchedDevice == nil || [selector length] < 2 ||
                    [selector characterAtIndex:0] != '"' ||
                    [selector characterAtIndex:[selector length] - 1] != '"' ||
                    [[selector substringWithRange:NSMakeRange(1, [selector length] - 2)] length] == 0) {
                    report(line, @"section must be [general], [mouse], [trackpad], or a device followed by a quoted application");
                    section = @"invalid";
                    continue;
                }
                section = matchedDevice;
                application = [selector substringWithRange:NSMakeRange(1, [selector length] - 2)];
                NSMutableDictionary *scopes = [section isEqualToString:@"mouse"]
                    ? mouseScopes : trackpadScopes;
                NSMutableArray *order = [section isEqualToString:@"mouse"]
                    ? mouseScopeOrder : trackpadScopeOrder;
                if ([scopes objectForKey:application] == nil) {
                    [scopes setObject:[NSMutableArray array] forKey:application];
                    [order addObject:application];
                }
            }
            continue;
        }

        NSString *expandedValue = nil;
        NSNumber *expandedDefer = nil;
        NSNumber *expandedHaptic = nil;
        BOOL expandedInvalid = NO;
        NSRange openingBrace = [line rangeOfString:@"{"];
        NSUInteger closingBraceLocation = unquotedClosingBraceLocation(line);
        NSRange closingBrace = NSMakeRange(closingBraceLocation, closingBraceLocation == NSNotFound ? 0 : 1);
        NSRange firstEquals = [line rangeOfString:@"="];
        BOOL expanded = openingBrace.location != NSNotFound &&
            closingBrace.location != NSNotFound &&
            closingBrace.location > openingBrace.location &&
            (firstEquals.location == NSNotFound || openingBrace.location < firstEquals.location);
        if (expanded) {
            NSString *tail = [[line substringFromIndex:closingBrace.location + 1]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([tail length] > 0) {
                report(line, @"nothing may follow an expanded binding block");
                continue;
            }
            NSString *body = [line substringWithRange:NSMakeRange(
                openingBrace.location + 1, closingBrace.location - openingBrace.location - 1)];
            NSArray *properties = splitExpandedProperties(body);
            for (NSString *rawProperty in properties) {
                NSString *property = [rawProperty stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([property length] == 0)
                    continue;
                NSRange propertyEquals = [property rangeOfString:@"="];
                if (propertyEquals.location == NSNotFound) {
                    report(line, @"expanded properties use name = value and commas between properties");
                    expandedInvalid = YES;
                    break;
                }
                NSString *propertyName = [[[property substringToIndex:propertyEquals.location]
                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
                NSString *propertyValue = [[property substringFromIndex:propertyEquals.location + 1]
                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if ([propertyName isEqualToString:@"action"]) {
                    if ([propertyValue length] < 2 ||
                        [propertyValue characterAtIndex:0] != '"' ||
                        [propertyValue characterAtIndex:[propertyValue length] - 1] != '"') {
                        report(line, @"an expanded action value must be in double quotes");
                        expandedInvalid = YES;
                        break;
                    }
                    expandedValue = propertyValue;
                } else if ([propertyName isEqualToString:@"defer"]) {
                    BOOL deferValue = NO;
                    if (!parseBooleanValue(propertyValue, &deferValue)) {
                        report(line, @"defer must be true, false, yes, no, on, off, 1, or 0");
                        expandedInvalid = YES;
                        break;
                    }
                    expandedDefer = @(deferValue);
                } else if ([propertyName isEqualToString:@"haptic"]) {
                    BOOL hapticValue = NO;
                    if (!parseBooleanValue(propertyValue, &hapticValue)) {
                        report(line, @"haptic must be true, false, yes, no, on, off, 1, or 0");
                        expandedInvalid = YES;
                        break;
                    }
                    expandedHaptic = @(hapticValue);
                } else {
                    report(line, [NSString stringWithFormat:@"no binding property named \"%@\"", propertyName]);
                    expandedInvalid = YES;
                    break;
                }
            }
            if (expandedInvalid)
                continue;
            if (expandedValue == nil && application == nil) {
                report(line, @"a global expanded binding requires an action property");
                continue;
            }
        }

        NSRange eq = expanded ? NSMakeRange(NSNotFound, 0) : [line rangeOfString:@"="];
        if (eq.location == NSNotFound) {
            if (!expanded) {
                report(line, @"not a setting: expected name = value");
                continue;
            }
        }
        NSString *key = [[line substringToIndex:expanded ? openingBrace.location : eq.location]
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *value = expanded ? expandedValue :
            [[line substringFromIndex:eq.location + 1]
             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        key = [key lowercaseString];

        NSString *device = section;

        if ([device isEqualToString:@"mouse"] || [device isEqualToString:@"trackpad"]) {
            NSDictionary *slugs = [device isEqualToString:@"mouse"]
                ? [Config mouseGestureSlugs] : [Config trackpadGestureSlugs];
            NSArray *engineNames = [slugs objectForKey:key];
            if (engineNames == nil) {
                report(line, [NSString stringWithFormat:@"no %@ gesture named \"%@\"", device, key]);
                continue;
            }
            if (expandedDefer != nil && ![key hasSuffix:@"-tap"]) {
                report(line, @"defer is available only for tap gestures");
                continue;
            }
            if (expandedHaptic != nil && [device isEqualToString:@"mouse"]) {
                report(line, @"haptic is available only for trackpad bindings");
                continue;
            }
            NSDictionary *binding = expanded && expandedValue == nil
                ? @{ @"Gesture": @"", @"InheritAction": @YES,
                     @"SourceLine": @(lineNumber), @"SourceText": line }
                : parseBinding(value);
            if (binding == nil) {
                NSString *unquoted = stripQuotes(value);
                if ([[unquoted lowercaseString] hasPrefix:@"url:"])
                    report(line, urlBindingProblem([unquoted substringFromIndex:4]));
                else if ([[unquoted lowercaseString] hasPrefix:@"script:"]) {
                    NSString *problem = nil;
                    resolvedScriptPath([unquoted substringFromIndex:7], &problem);
                    report(line, problem);
                }
                else
                    report(line, [NSString stringWithFormat:@"\"%@\" is not a key, shortcut, action, URL, or script", value]);
                continue;
            }

            NSMutableDictionary *scopes = [device isEqualToString:@"mouse"]
                ? mouseScopes : trackpadScopes;
            NSString *scopeName = application ?: @"All Applications";
            NSMutableArray *target = [scopes objectForKey:scopeName];
            NSString *declarationKey = [NSString stringWithFormat:@"%@|%@|%@",
                                         device, scopeName, key];
            if ([[binding objectForKey:@"InheritAction"] boolValue] ||
                [[binding objectForKey:@"Enable"] boolValue])
                [activeBindingKeys addObject:declarationKey];
            else
                [activeBindingKeys removeObject:declarationKey];
            for (NSString *name in engineNames) {
                NSMutableDictionary *g = [[binding mutableCopy] autorelease];
                [g setObject:name forKey:@"Gesture"];
                [g setObject:@(lineNumber) forKey:@"SourceLine"];
                [g setObject:line forKey:@"SourceText"];
                if ([[binding objectForKey:@"InheritAction"] boolValue])
                    [g setObject:declarationKey forKey:@"SourceBindingKey"];
                if (expandedDefer != nil)
                    [g setObject:expandedDefer forKey:@"Defer"];
                if (expandedHaptic != nil)
                    [g setObject:expandedHaptic forKey:@"HapticFeedback"];
                [target addObject:g];
            }
        } else if ([device isEqualToString:@"general"]) {
            if (![knownSettingNames() containsObject:key]) {
                report(line, [NSString stringWithFormat:@"no setting named \"%@\"", key]);
                continue;
            }
            if ([key isEqualToString:@"config-version"] && ![stripQuotes(value) isEqualToString:@"2"]) {
                report(line, [NSString stringWithFormat:
                    @"configuration format \"%@\" is not supported; this version reads format 2",
                    value]);
                unsupportedVersion = YES;
            }
            if ([@[@"enable-mouse", @"enable-trackpad", @"haptic-feedback", @"verbose-logging",
                   @"experimental-mouse-click-gestures"] containsObject:key] &&
                !parseBooleanValue(value, NULL)) {
                report(line, [NSString stringWithFormat:
                    @"%@ must be true, false, yes, no, on, off, 1, or 0", key]);
                continue;
            }
            if ([key isEqualToString:@"tap-speed"] && !parsePositiveNumber(value, NULL)) {
                report(line, @"tap-speed must be a positive number of seconds");
                continue;
            }
            if ([key isEqualToString:@"dominant-hand"] &&
                ![@[@"left", @"right"] containsObject:[[stripQuotes(value) lowercaseString]
                                                         stringByTrimmingCharactersInSet:
                                                             [NSCharacterSet whitespaceCharacterSet]]]) {
                report(line, @"dominant-hand must be left or right");
                continue;
            }
            [general setObject:value forKey:key];
        } else {
            report(line, [NSString stringWithFormat:@"no section or device named \"%@\"", device]);
        }
    }

    if (pendingBlock != nil) {
        lineNumber = pendingBlockLine;
        report(pendingBlock, @"expanded binding is missing a closing }");
    }

    // A newer or malformed format may reinterpret otherwise valid lines. Keep
    // the entire previous configuration instead of applying a partial guess.
    if (unsupportedVersion)
        return nil;

    NSString *(^str)(NSString *, NSString *) = ^(NSString *k, NSString *fallback) {
        NSString *v = [general objectForKey:k];
        return v ?: fallback;
    };

    BOOL leftHanded = [[stripQuotes(str(@"dominant-hand", @"right")) lowercaseString]
        isEqualToString:@"left"];

    // Magic Mouse physical clicks depend on contact timing and hand posture
    // that vary across people and devices. Keep them available for testing,
    // but do not silently activate them in the supported gesture set.
    if (!parseBoolean(str(@"experimental-mouse-click-gestures", @"false"), NO)) {
        NSSet *clickNames = [NSSet setWithArray:@[@"Two-Finger Click", @"Three-Finger Click"]];
        NSMutableSet *reportedBindings = [NSMutableSet set];
        for (NSString *scopeName in mouseScopeOrder) {
            NSMutableArray *bindings = [mouseScopes objectForKey:scopeName];
            for (NSInteger i = (NSInteger)[bindings count] - 1; i >= 0; i--) {
                NSDictionary *binding = [bindings objectAtIndex:(NSUInteger)i];
                if (![clickNames containsObject:[binding objectForKey:@"Gesture"]])
                    continue;
                NSString *sourceKey = [NSString stringWithFormat:@"%@|%@",
                    [binding objectForKey:@"SourceLine"], [binding objectForKey:@"SourceText"]];
                if (![reportedBindings containsObject:sourceKey]) {
                    [reportedBindings addObject:sourceKey];
                    [problems addObject:[NSString stringWithFormat:
                        @"line %@:  %@\n          requires experimental-mouse-click-gestures = true in [general]",
                        [binding objectForKey:@"SourceLine"], [binding objectForKey:@"SourceText"]]];
                }
                [bindings removeObjectAtIndex:(NSUInteger)i];
            }
        }
        [activeBindingKeys filterUsingPredicate:[NSPredicate predicateWithBlock:
            ^BOOL(NSString *key, NSDictionary *unused) {
                return !([key hasPrefix:@"mouse|"] &&
                         ([key hasSuffix:@"|two-finger-click"] ||
                          [key hasSuffix:@"|three-finger-click"]));
            }]];
    }

    NSArray *(^commands)(NSMutableDictionary *, NSMutableArray *) =
        ^NSArray *(NSMutableDictionary *scopes, NSMutableArray *order) {
            NSMutableArray *result = [NSMutableArray array];
            NSMutableSet *reportedMissingActions = [NSMutableSet set];
            NSMutableDictionary *globalByGesture = [NSMutableDictionary dictionary];
            for (NSDictionary *binding in [scopes objectForKey:@"All Applications"])
                [globalByGesture setObject:binding forKey:[binding objectForKey:@"Gesture"]];
            for (NSString *app in order) {
                NSArray *configured = [scopes objectForKey:app];
                NSMutableArray *resolved = [NSMutableArray array];
                for (NSDictionary *binding in configured) {
                    if (![[binding objectForKey:@"InheritAction"] boolValue]) {
                        [resolved addObject:binding];
                        continue;
                    }
                    NSDictionary *global = [globalByGesture objectForKey:[binding objectForKey:@"Gesture"]];
                    if (global == nil) {
                        NSString *sourceKey = [binding objectForKey:@"SourceBindingKey"];
                        [activeBindingKeys removeObject:sourceKey];
                        if (![reportedMissingActions containsObject:sourceKey]) {
                            [reportedMissingActions addObject:sourceKey];
                            [problems addObject:[NSString stringWithFormat:
                                @"line %@:  %@\n          app property overrides require a global action for the same gesture",
                                [binding objectForKey:@"SourceLine"], [binding objectForKey:@"SourceText"]]];
                        }
                        continue;
                    }
                    NSMutableDictionary *merged = [[global mutableCopy] autorelease];
                    for (NSString *key in binding) {
                        if (![@[@"InheritAction", @"SourceLine", @"SourceText", @"SourceBindingKey"] containsObject:key])
                            [merged setObject:[binding objectForKey:key] forKey:key];
                    }
                    [resolved addObject:merged];
                }
                [result addObject:@{@"Application": app,
                                    @"Path": @"",
                                    @"Gestures": resolved}];
            }
            return result;
        };

    NSArray *resolvedTrackpadCommands = commands(trackpadScopes, trackpadScopeOrder);
    NSArray *resolvedMouseCommands = commands(mouseScopes, mouseScopeOrder);

    return @{
        @"enAll": @1,
        @"ClickSpeed": @([str(@"tap-speed", @"0.25") floatValue]),
        @"Sensitivity": @4.6666,
        @"ShowIcon": @1,
        @"BindingCount": @([activeBindingKeys count]),
        @"HapticFeedback": @(parseBoolean(str(@"haptic-feedback", @"true"), YES) ? 1 : 0),
        @"ExperimentalMouseClickGestures": @(parseBoolean(str(@"experimental-mouse-click-gestures", @"false"), NO) ? 1 : 0),
        @"LogLevel": @(parseBoolean(str(@"verbose-logging", @"false"), NO) ? 3 : 1),
        @"enTPAll": @(parseBoolean(str(@"enable-trackpad", @"true"), YES) ? 1 : 0),
        @"enMMAll": @(parseBoolean(str(@"enable-mouse", @"true"), YES) ? 1 : 0),
        @"Handed": @(leftHanded ? 1 : 0),
        @"MMHanded": @(leftHanded ? 1 : 0),
        @"enCharRegTP": @0,
        @"enCharRegMM": @0,
        @"charRegMouseButton": @0,
        @"charRegIndexRingDistance": @0.33,
        @"enOneDrawing": @0,
        @"enTwoDrawing": @1,
        @"TrackpadCommands": resolvedTrackpadCommands,
        @"MagicMouseCommands": resolvedMouseCommands,
        @"RecognitionCommands": @[@{@"Application": @"All Applications", @"Path": @"", @"Gestures": @[]}],
    };
}

@end
