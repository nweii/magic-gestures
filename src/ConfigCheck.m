//
//  ConfigCheck.m
//  MagicGestures
//
//  Copyright 2026 Nathan Cheng. All rights reserved.
//
//  Asserts that a configuration file parses into the keycodes and flags the
//  engine will dispatch. Run with scripts/check.sh.
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import "Config.h"

static int failures = 0;

static void fail(NSString *what, id expected, id actual) {
    fprintf(stderr, "FAIL  %s\n      expected %s\n      got      %s\n",
            [what UTF8String], [[expected description] UTF8String],
            [[actual description] UTF8String]);
    failures++;
}

// Finds a binding by its engine gesture name in parsed settings.
static NSDictionary *bindingFor(NSDictionary *settings, NSString *deviceKey, NSString *gesture) {
    for (NSDictionary *app in [settings objectForKey:deviceKey]) {
        for (NSDictionary *g in [app objectForKey:@"Gestures"]) {
            if ([[g objectForKey:@"Gesture"] isEqualToString:gesture])
                return g;
        }
    }
    return nil;
}

static NSDictionary *parse(NSString *text) {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mg-check.conf"];
    [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    return [Config settingsFromFile:path];
}

static NSDictionary *parseWithProblems(NSString *text, NSArray **problems) {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"mg-check.conf"];
    [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    return [Config settingsFromFile:path problems:problems];
}

static NSString *section(NSString *text, NSString *start, NSString *end) {
    NSRange startRange = [text rangeOfString:start];
    if (startRange.location == NSNotFound)
        return nil;
    NSUInteger bodyStart = NSMaxRange(startRange);
    NSRange searchRange = NSMakeRange(bodyStart, [text length] - bodyStart);
    NSRange endRange = [text rangeOfString:end options:0 range:searchRange];
    NSUInteger bodyEnd = endRange.location == NSNotFound ? [text length] : endRange.location;
    return [text substringWithRange:NSMakeRange(bodyStart, bodyEnd - bodyStart)];
}

static void expectDeviceSlugs(NSString *label, NSString *text, NSDictionary *slugs) {
    if (text == nil) {
        fail(label, @"a device section", @"missing");
        return;
    }
    for (NSString *slug in slugs) {
        if ([text rangeOfString:slug].location == NSNotFound)
            fail([NSString stringWithFormat:@"%@ documents %@", label, slug], @"present", @"missing");
    }
}

static void expectKey(NSString *label, NSString *value, int keycode, NSUInteger flags) {
    NSString *conf = [NSString stringWithFormat:@"[mouse]\nhold-right-tap-left = %@\n", value];
    NSDictionary *g = bindingFor(parse(conf), @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap");
    if (g == nil) {
        fail(label, @"a binding", @"none");
        return;
    }
    if ([[g objectForKey:@"KeyCode"] intValue] != keycode)
        fail([label stringByAppendingString:@" keycode"], @(keycode), [g objectForKey:@"KeyCode"]);
    if ([[g objectForKey:@"ModifierFlags"] unsignedIntegerValue] != flags)
        fail([label stringByAppendingString:@" flags"], @(flags), [g objectForKey:@"ModifierFlags"]);
}

int main(void) {
    @autoreleasepool {
        NSUInteger CMD = kCGEventFlagMaskCommand;
        NSUInteger SHIFT = kCGEventFlagMaskShift;
        NSUInteger CTRL = kCGEventFlagMaskControl;

        // Bare keys and key names containing the separator must parse.
        expectKey(@"return", @"return", 36, 0);
        expectKey(@"enter alias", @"enter", 36, 0);
        expectKey(@"escape", @"escape", 53, 0);
        expectKey(@"page-down survives hyphen split", @"page-down", 121, 0);
        expectKey(@"forward-delete survives hyphen split", @"forward-delete", 117, 0);

        // Every documented spelling of a chord must produce the same binding.
        expectKey(@"plus separator", @"cmd+shift+a", 0, CMD | SHIFT);
        expectKey(@"hyphen separator", @"command-shift-a", 0, CMD | SHIFT);
        expectKey(@"space separator", @"Cmd Shift A", 0, CMD | SHIFT);
        expectKey(@"symbols without separators", @"⌘⇧A", 0, CMD | SHIFT);
        expectKey(@"mixed case", @"CMD+Shift+A", 0, CMD | SHIFT);
        expectKey(@"alt is option", @"ctrl+alt+right", 124, CTRL | kCGEventFlagMaskAlternate);
        expectKey(@"quoted value", @"\"cmd+shift+a\"", 0, CMD | SHIFT);

        NSDictionary *punctuation = @{
            @"[": @33, @"]": @30, @"-": @27, @"=": @24, @";": @41,
            @"'": @39, @",": @43, @".": @47, @"/": @44, @"\\": @42, @"`": @50,
        };
        for (NSString *key in punctuation)
            expectKey([@"punctuation " stringByAppendingString:key], key,
                      [[punctuation objectForKey:key] intValue], 0);

        // An unknown token must reject the value instead of binding the last
        // token that happened to parse.
        for (NSString *bad in @[@"cmd+bogus+a", @"a+b", @"cmd+", @"nonsense"]) {
            NSString *conf = [NSString stringWithFormat:@"[mouse]\nhold-right-tap-left = %@\n", bad];
            if (bindingFor(parse(conf), @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap") != nil)
                fail([@"malformed value rejected: " stringByAppendingString:bad], @"nothing", @"a binding");
        }

        // A slug mapped to two engine gesture names must produce both bindings.
        NSDictionary *s = parse(@"[mouse]\nhold-right-tap-left = return\n");
        if (bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Far-Tap") == nil)
            fail(@"one slug binds near and far", @"far variant present", @"missing");

        // A built-in action must dispatch by name instead of as a keystroke.
        s = parse(@"[trackpad]\nthree-finger-tap = middle-click\n");
        NSDictionary *g = bindingFor(s, @"TrackpadCommands", @"Three-Finger Tap");
        if (![[g objectForKey:@"IsAction"] boolValue])
            fail(@"action is not a keystroke", @YES, [g objectForKey:@"IsAction"]);
        if (![[g objectForKey:@"Command"] isEqualToString:@"Middle Click"])
            fail(@"action name", @"Middle Click", [g objectForKey:@"Command"]);

        // URL bindings preserve their payload exactly and dispatch as actions.
        NSString *customURL = @"raycast://extensions/Raycast/raycast-ai/ai-chat?ref=A%20B&mode=Fast#Prompt";
        s = parse([NSString stringWithFormat:@"[mouse]\nhold-right-tap-left = url:%@\n", customURL]);
        g = bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap");
        if (![[g objectForKey:@"OpenURL"] isEqualToString:customURL])
            fail(@"URL preserves case, query, escapes, and fragment", customURL, [g objectForKey:@"OpenURL"]);
        if (![[g objectForKey:@"IsAction"] boolValue])
            fail(@"URL is not a keystroke", @YES, [g objectForKey:@"IsAction"]);

        s = parse(@"[trackpad]\nthree-finger-tap = url:obsidian://daily # trailing comment\n");
        g = bindingFor(s, @"TrackpadCommands", @"Three-Finger Tap");
        if (![[g objectForKey:@"OpenURL"] isEqualToString:@"obsidian://daily"])
            fail(@"URL permits a trailing comment", @"obsidian://daily", [g objectForKey:@"OpenURL"]);

        NSDictionary *badURLs = @{
            @"url:raycast//extensions": @"URL is missing a valid scheme followed by \":\"",
            @"url:1raycast://extensions": @"URL scheme must begin with a letter",
            @"url:ray cast://extensions": @"URL contains unencoded whitespace",
            @"url:https://example.com/%ZZ": @"URL contains a malformed percent escape",
        };
        for (NSString *bad in badURLs) {
            NSArray *problems = nil;
            NSString *conf = [NSString stringWithFormat:@"[mouse]\nhold-right-tap-left = %@\n", bad];
            s = parseWithProblems(conf, &problems);
            if (bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap") != nil)
                fail([@"malformed URL rejected: " stringByAppendingString:bad], @"nothing", @"a binding");
            NSString *problem = [problems count] > 0 ? [problems objectAtIndex:0] : @"";
            if ([problem rangeOfString:[badURLs objectForKey:bad]].location == NSNotFound)
                fail([@"malformed URL explains: " stringByAppendingString:bad], [badURLs objectForKey:bad], problem);
        }

        // Substitutions are validated at reload and resolved only when the
        // gesture fires. URL encoding treats the clipboard as one component.
        NSDateComponents *parts = [[[NSDateComponents alloc] init] autorelease];
        [parts setYear:2026];
        [parts setMonth:7];
        [parts setDay:31];
        [parts setHour:14];
        [parts setMinute:5];
        NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] autorelease];
        [calendar setTimeZone:[NSTimeZone localTimeZone]];
        NSDate *date = [calendar dateFromComponents:parts];
        NSString *problem = nil;
        NSString *resolved = [Config URLByResolvingSubstitutions:
                              @"things:///add?when={{datetime:yyyy-MM-dd'T'HH:mm}}&title={{clipboard|urlencode}}"
                                                        clipboard:@"Café & tea?"
                                                             date:date
                                                          problem:&problem];
        NSString *expectedURL = @"things:///add?when=2026-07-31T14:05&title=Caf%C3%A9%20%26%20tea%3F";
        if (![resolved isEqualToString:expectedURL])
            fail(@"substitutions resolve deterministically", expectedURL, resolved ?: problem);

        resolved = [Config URLByResolvingSubstitutions:@"example://open/{{clipboard}}"
                                             clipboard:@"already-safe"
                                                  date:date
                                               problem:&problem];
        if (![resolved isEqualToString:@"example://open/already-safe"])
            fail(@"raw clipboard substitution", @"example://open/already-safe", resolved ?: problem);

        resolved = [Config URLByResolvingSubstitutions:@"example://open?q={{clipboard|urlencode}}"
                                             clipboard:nil
                                                  date:date
                                               problem:&problem];
        if (![resolved isEqualToString:@"example://open?q="])
            fail(@"empty clipboard becomes an empty value", @"example://open?q=", resolved ?: problem);

        resolved = [Config URLByResolvingSubstitutions:@"example://open?q={{clipboard}}"
                                             clipboard:@"two words"
                                                  date:date
                                               problem:&problem];
        if (resolved != nil || [problem rangeOfString:@"unencoded whitespace"].location == NSNotFound)
            fail(@"expanded URL is revalidated", @"unencoded whitespace problem", resolved ?: problem);

        NSDictionary *badSubstitutions = @{
            @"url:example://open?q={{clipbord}}": @"unknown substitution \"clipbord\"",
            @"url:example://open?q={{clipboard|encode}}": @"unknown clipboard substitution filter \"encode\"",
            @"url:example://open?q={{clipboard}": @"substitution has unmatched braces",
            @"url:example://open?q=clipboard}}": @"substitution has unmatched braces",
            @"url:example://open?q={{datetime:}}": @"datetime substitution needs a format",
            @"url:example://open?q={{datetime:yyyy-MM-dd'T}}": @"datetime substitution has an unmatched quote",
        };
        for (NSString *bad in badSubstitutions) {
            NSArray *problems = nil;
            NSString *conf = [NSString stringWithFormat:@"[mouse]\nhold-right-tap-left = %@\n", bad];
            s = parseWithProblems(conf, &problems);
            if (bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap") != nil)
                fail([@"malformed substitution rejected: " stringByAppendingString:bad], @"nothing", @"a binding");
            NSString *reported = [problems count] > 0 ? [problems objectAtIndex:0] : @"";
            if ([reported rangeOfString:[badSubstitutions objectForKey:bad]].location == NSNotFound)
                fail([@"malformed substitution explains: " stringByAppendingString:bad],
                     [badSubstitutions objectForKey:bad], reported);
        }

        s = parse(@"[mouse]\nhold-right-tap-left = url:https://example.com?q={{clipboard|urlencode}}\n");
        g = bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap");
        if (![[g objectForKey:@"OpenURL"] isEqualToString:@"https://example.com?q={{clipboard|urlencode}}"])
            fail(@"configured substitution remains unresolved", @"configured expression", [g objectForKey:@"OpenURL"]);

        // An inline device prefix must override the current section.
        s = parse(@"[mouse]\ntrackpad.hold-right-tap-left = escape\n");
        if (bindingFor(s, @"TrackpadCommands", @"One-Fix Left-Tap") == nil)
            fail(@"inline prefix overrides section", @"trackpad binding", @"missing");
        if (bindingFor(s, @"MagicMouseCommands", @"One-Fix Left-Tap") != nil)
            fail(@"inline prefix does not also bind the section device", @"nothing", @"a binding");

        NSArray *generalPrefixProblems = nil;
        s = parseWithProblems(@"general.enable-mouse = false\n", &generalPrefixProblems);
        if ([[s objectForKey:@"enMMAll"] intValue] != 1)
            fail(@"general prefix is rejected", @1, [s objectForKey:@"enMMAll"]);
        NSString *generalPrefixProblem = [generalPrefixProblems count] > 0
            ? [generalPrefixProblems objectAtIndex:0] : @"";
        if ([generalPrefixProblem rangeOfString:@"belong under a [general] header"].location == NSNotFound)
            fail(@"general prefix explains section form", @"[general] guidance", generalPrefixProblem);

        // Unrecognized names must be skipped without affecting valid lines.
        s = parse(@"[mouse]\nnot-a-gesture = return\nhold-right-tap-left = return\n");
        if (bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap") == nil)
            fail(@"unknown gesture does not abort the file", @"later binding present", @"missing");
        s = parse(@"[mouse]\nhold-right-tap-left = not-a-key\n");
        if (bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap") != nil)
            fail(@"unknown key is skipped", @"nothing", @"a binding");

        // Each accepted boolean spelling must parse.
        NSArray *truthy = @[@"true", @"yes", @"on", @"1"];
        for (NSString *v in truthy) {
            s = parse([NSString stringWithFormat:@"[general]\nenable-mouse = %@\n", v]);
            if ([[s objectForKey:@"enMMAll"] intValue] != 1)
                fail([@"boolean " stringByAppendingString:v], @1, [s objectForKey:@"enMMAll"]);
        }
        for (NSString *v in @[@"false", @"no", @"off", @"0"]) {
            s = parse([NSString stringWithFormat:@"[general]\nenable-mouse = %@\n", v]);
            if ([[s objectForKey:@"enMMAll"] intValue] != 0)
                fail([@"boolean " stringByAppendingString:v], @0, [s objectForKey:@"enMMAll"]);
        }

        NSArray *invalidSettings = @[
            @"[general]\nenable-mouse = maybe\n",
            @"[general]\nenable-trackpad = enabled\n",
            @"[general]\nverbose-logging = verbose\n",
            @"[general]\ntap-speed = soon\n",
            @"[general]\ntap-speed = 0\n",
            @"[general]\ntap-speed = -0.2\n",
        ];
        for (NSString *text in invalidSettings) {
            NSArray *problems = nil;
            parseWithProblems(text, &problems);
            if ([problems count] == 0)
                fail(@"invalid general setting is reported", @"a problem", @"none");
        }

        // Format 1 is explicit in new files and implicit in files written
        // before versioning. An unsupported format rejects the whole file.
        if (parse(@"[general]\nconfig-version = 1\n") == nil)
            fail(@"configuration format 1", @"settings", @"nothing");
        if (parse(@"[general]\nenable-mouse = true\n") == nil)
            fail(@"missing configuration version means format 1", @"settings", @"nothing");
        NSArray *versionProblems = nil;
        s = parseWithProblems(@"[general]\nconfig-version = 2\n", &versionProblems);
        if (s != nil)
            fail(@"unsupported configuration format rejects file", @"nothing", @"settings");
        NSString *versionProblem = [versionProblems count] > 0 ? [versionProblems objectAtIndex:0] : @"";
        if ([versionProblem rangeOfString:@"this version reads format 1"].location == NSNotFound)
            fail(@"unsupported configuration format explains rejection",
                 @"format 1 explanation", versionProblem);

        // Comments and blank lines must not produce bindings. A # without
        // preceding whitespace is ordinary value content, as URL fragments need.
        s = parse(@"# comment\n\n[mouse]\nhold-right-tap-left = return # trailing\n");
        g = bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap");
        if ([[g objectForKey:@"KeyCode"] intValue] != 36)
            fail(@"trailing comment stripped", @36, [g objectForKey:@"KeyCode"]);

        // The shipped example must parse before it is copied into a user config.
        NSString *example = [[[NSProcessInfo processInfo] arguments] count] > 1
            ? [[NSProcessInfo processInfo] arguments][1] : nil;
        if (example != nil) {
            NSDictionary *parsed = [Config settingsFromFile:example];
            if (parsed == nil)
                fail(@"shipped example parses", @"a settings dictionary", @"nil");
            else if (bindingFor(parsed, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap") == nil)
                fail(@"shipped example binds its documented default", @"a binding", @"missing");
        }

        // Every gesture a slug can reach must have a menu phrase, or the menu
        // falls back to the engine's internal name.
        for (NSDictionary *slugs in @[[Config mouseGestureSlugs], [Config trackpadGestureSlugs]]) {
            for (NSString *slug in slugs) {
                for (NSString *engineName in [slugs objectForKey:slug]) {
                    if ([[Config humanNameForGesture:engineName] isEqualToString:engineName])
                        fail([@"menu phrase for " stringByAppendingString:engineName],
                             @"a description of the motion", engineName);
                }
            }
        }

        // Every slug must appear in the notes installed beside the config, or
        // it exists without being documented anywhere the user will look.
        NSArray *args = [[NSProcessInfo processInfo] arguments];
        NSUInteger documentationEnd = MIN([args count], 4);
        for (NSUInteger i = 2; i < documentationEnd; i++) {
            NSString *doc = [NSString stringWithContentsOfFile:args[i] encoding:NSUTF8StringEncoding error:NULL];
            if (doc == nil)
                continue;
            NSString *name = [args[i] lastPathComponent];
            for (NSDictionary *slugs in @[[Config mouseGestureSlugs], [Config trackpadGestureSlugs]]) {
                for (NSString *slug in slugs) {
                    if ([doc rangeOfString:slug].location == NSNotFound)
                        fail([NSString stringWithFormat:@"%@ documents %@", name, slug], @"present", @"missing");
                }
            }
        }

        if ([args count] > 3) {
            NSString *notes = [NSString stringWithContentsOfFile:args[2] encoding:NSUTF8StringEncoding error:NULL];
            expectDeviceSlugs(@"installed notes mouse section",
                              section(notes, @"Mouse: `", @"\n\nTrackpad:"),
                              [Config mouseGestureSlugs]);
            expectDeviceSlugs(@"installed notes trackpad section",
                              section(notes, @"Trackpad: `", @"\n\nThe `hold-`"),
                              [Config trackpadGestureSlugs]);

            NSString *reference = [NSString stringWithContentsOfFile:args[3] encoding:NSUTF8StringEncoding error:NULL];
            expectDeviceSlugs(@"gesture reference mouse section",
                              section(reference, @"## Magic Mouse", @"## Magic Trackpad"),
                              [Config mouseGestureSlugs]);
            expectDeviceSlugs(@"gesture reference trackpad section",
                              section(reference, @"## Magic Trackpad", @"## What a gesture can send"),
                              [Config trackpadGestureSlugs]);
        }

        // Every exposed engine name needs a dispatch site for its own device.
        // A matching name on the other device does not make a binding reachable.
        if ([args count] > 4) {
            NSString *engine = [NSString stringWithContentsOfFile:args[4] encoding:NSUTF8StringEncoding error:NULL];
            NSArray *devices = @[
                @[[Config mouseGestureSlugs], @"MAGICMOUSE"],
                @[[Config trackpadGestureSlugs], @"TRACKPAD"],
            ];
            for (NSArray *device in devices) {
                NSDictionary *slugs = device[0];
                NSString *constant = device[1];
                for (NSString *slug in slugs) {
                    for (NSString *engineName in [slugs objectForKey:slug]) {
                        NSString *dispatch = [NSString stringWithFormat:@"dispatchCommand(@\"%@\", %@)", engineName, constant];
                        if ([engine rangeOfString:dispatch].location == NSNotFound)
                            fail([NSString stringWithFormat:@"%@ %@ has a recognizer dispatch", constant, slug], dispatch, @"missing");
                    }
                }
            }

            for (NSString *command in [[Config actionNames] allValues]) {
                NSString *branch = [NSString stringWithFormat:@"isEqualToString:@\"%@\"", command];
                if ([engine rangeOfString:branch].location == NSNotFound)
                    fail([@"action dispatch " stringByAppendingString:command], branch, @"missing");
            }

            NSArray *invocations = @[
                @"gestureMagicMouseThreeFingerTap(data, nFingers, timestamp, thumbPresent)",
                @"gestureMagicMouseTwoFingerSwipe(data, nFingers, timestamp, thumbPresent)",
                @"gestureTrackpadTwoFingerTap(data, nFingers, timestamp)",
                @"gestureTrackpadHoldSlide(data, nFingers)",
            ];
            for (NSString *invocation in invocations) {
                if ([engine rangeOfString:invocation].location == NSNotFound)
                    fail(@"device callback invokes exposed recognizer", invocation, @"missing");
            }

            NSString *mouseHoldTap = section(engine,
                @"static int gestureMagicMouseOneFixOneTap", @"static int magicMouseCallback");
            if ([mouseHoldTap rangeOfString:@"customMagicMouseTapSuppressionUntil ="].location == NSNotFound)
                fail(@"mouse hold-tap suppresses competing tap recognizers",
                     @"tap suppression", @"missing");
        }

        if (failures == 0) {
            printf("config parser: all checks passed\n");
            return 0;
        }
        fprintf(stderr, "config parser: %d failure(s)\n", failures);
        return 1;
    }
}
