//
//  Config.m
//  MagicGestures
//
//  Copyright 2026 Nathan Cheng. All rights reserved.
//

#import "Config.h"
#import <Carbon/Carbon.h>
#import <ApplicationServices/ApplicationServices.h>

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

// Returns an engine gesture dictionary, or nil for an unrecognized value.
// Keystrokes contain modifiers and one key. Actions are dispatched by name.
static NSDictionary *parseBinding(NSString *rawValue) {
    NSString *unquoted = stripQuotes([rawValue stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]]);
    NSString *value = [unquoted lowercaseString];
    if ([value length] == 0)
        return nil;

    if ([value hasPrefix:@"url:"]) {
        NSString *url = [unquoted substringFromIndex:4];
        if (urlBindingProblem(url) != nil)
            return nil;
        return @{ @"Gesture": @"", @"Command": url, @"OpenURL": url,
                  @"IsAction": @YES, @"ModifierFlags": @0, @"KeyCode": @0,
                  @"Enable": @YES };
    }

    NSString *action = [actionNames() objectForKey:value];
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
    for (NSString *raw in tokens) {
        NSString *t = [raw stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([t length] == 0)
            continue;
        NSNumber *flag = [modifierNames() objectForKey:t];
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
        s = [[NSSet setWithArray:@[@"config-version", @"enable-mouse", @"enable-trackpad", @"tap-speed",
                                   @"verbose-logging"]] retain];
    }
    return s;
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
    NSMutableDictionary *general = [NSMutableDictionary dictionary];
    NSString *section = @"general";
    __block NSInteger lineNumber = 0;
    __block BOOL unsupportedVersion = NO;

    void (^report)(NSString *, NSString *) = ^(NSString *text, NSString *reason) {
        [problems addObject:[NSString stringWithFormat:@"line %ld:  %@\n          %@",
                             (long)lineNumber, text, reason]];
    };

    for (NSString *rawLine in [text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
        lineNumber++;
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

        if ([line hasPrefix:@"["] && [line hasSuffix:@"]"]) {
            section = [[line substringWithRange:NSMakeRange(1, [line length] - 2)]
                       stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            section = [section lowercaseString];
            continue;
        }

        NSRange eq = [line rangeOfString:@"="];
        if (eq.location == NSNotFound) {
            report(line, @"not a setting: expected name = value");
            continue;
        }
        NSString *key = [[line substringToIndex:eq.location]
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *value = [[line substringFromIndex:eq.location + 1]
                           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        key = [key lowercaseString];

        // An inline device name overrides the current section. This keeps an
        // appended binding independent of the section above it.
        NSString *device = section;
        NSRange dot = [key rangeOfString:@"."];
        if (dot.location != NSNotFound) {
            device = [key substringToIndex:dot.location];
            key = [key substringFromIndex:dot.location + 1];
            if ([device isEqualToString:@"general"]) {
                report(line, @"general settings belong under a [general] header");
                continue;
            }
        }

        if ([device isEqualToString:@"mouse"] || [device isEqualToString:@"trackpad"]) {
            NSDictionary *slugs = [device isEqualToString:@"mouse"]
                ? [Config mouseGestureSlugs] : [Config trackpadGestureSlugs];
            NSArray *engineNames = [slugs objectForKey:key];
            if (engineNames == nil) {
                report(line, [NSString stringWithFormat:@"no %@ gesture named \"%@\"", device, key]);
                continue;
            }
            NSDictionary *binding = parseBinding(value);
            if (binding == nil) {
                NSString *unquoted = stripQuotes(value);
                if ([[unquoted lowercaseString] hasPrefix:@"url:"])
                    report(line, urlBindingProblem([unquoted substringFromIndex:4]));
                else
                    report(line, [NSString stringWithFormat:@"\"%@\" is not a key, shortcut, action, or URL", value]);
                continue;
            }

            NSMutableArray *target = [device isEqualToString:@"mouse"] ? mouse : trackpad;
            for (NSString *name in engineNames) {
                NSMutableDictionary *g = [[binding mutableCopy] autorelease];
                [g setObject:name forKey:@"Gesture"];
                [target addObject:g];
            }
        } else if ([device isEqualToString:@"general"]) {
            if (![knownSettingNames() containsObject:key])
                report(line, [NSString stringWithFormat:@"no setting named \"%@\"", key]);
            if ([key isEqualToString:@"config-version"] && ![stripQuotes(value) isEqualToString:@"1"]) {
                report(line, [NSString stringWithFormat:
                    @"configuration format \"%@\" is not supported; this version reads format 1",
                    value]);
                unsupportedVersion = YES;
            }
            [general setObject:value forKey:key];
        } else {
            report(line, [NSString stringWithFormat:@"no section or device named \"%@\"", device]);
        }
    }

    // A newer or malformed format may reinterpret otherwise valid lines. Keep
    // the entire previous configuration instead of applying a partial guess.
    if (unsupportedVersion)
        return nil;

    NSString *(^str)(NSString *, NSString *) = ^(NSString *k, NSString *fallback) {
        NSString *v = [general objectForKey:k];
        return v ?: fallback;
    };

    return @{
        @"enAll": @1,
        @"ClickSpeed": @([str(@"tap-speed", @"0.25") floatValue]),
        @"Sensitivity": @4.6666,
        @"ShowIcon": @1,
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
