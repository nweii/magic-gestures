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

static void expectKey(NSString *label, NSString *value, int keycode, NSUInteger flags) {
    NSString *conf = [NSString stringWithFormat:@"[mouse]\nhold-middle-tap-index = %@\n", value];
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

        // A slug mapped to two engine gesture names must produce both bindings.
        NSDictionary *s = parse(@"[mouse]\nhold-middle-tap-index = return\n");
        if (bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Far-Tap") == nil)
            fail(@"one slug binds near and far", @"far variant present", @"missing");

        // A built-in action must dispatch by name instead of as a keystroke.
        s = parse(@"[trackpad]\nthree-finger-tap = middle-click\n");
        NSDictionary *g = bindingFor(s, @"TrackpadCommands", @"Three-Finger Tap");
        if (![[g objectForKey:@"IsAction"] boolValue])
            fail(@"action is not a keystroke", @YES, [g objectForKey:@"IsAction"]);
        if (![[g objectForKey:@"Command"] isEqualToString:@"Middle Click"])
            fail(@"action name", @"Middle Click", [g objectForKey:@"Command"]);

        // An inline device prefix must override the current section.
        s = parse(@"[mouse]\ntrackpad.hold-tap-left = escape\n");
        if (bindingFor(s, @"TrackpadCommands", @"One-Fix Left-Tap") == nil)
            fail(@"inline prefix overrides section", @"trackpad binding", @"missing");
        if (bindingFor(s, @"MagicMouseCommands", @"One-Fix Left-Tap") != nil)
            fail(@"inline prefix does not also bind the section device", @"nothing", @"a binding");

        // Unrecognized names must be skipped without affecting valid lines.
        s = parse(@"[mouse]\nnot-a-gesture = return\nhold-middle-tap-index = return\n");
        if (bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap") == nil)
            fail(@"unknown gesture does not abort the file", @"later binding present", @"missing");
        s = parse(@"[mouse]\nhold-middle-tap-index = not-a-key\n");
        if (bindingFor(s, @"MagicMouseCommands", @"Middle-Fix Index-Near-Tap") != nil)
            fail(@"unknown key is skipped", @"nothing", @"a binding");

        // Each accepted boolean spelling must parse.
        NSArray *truthy = @[@"true", @"yes", @"on", @"1"];
        for (NSString *v in truthy) {
            s = parse([NSString stringWithFormat:@"[general]\nshow-menu-bar-icon = %@\n", v]);
            if ([[s objectForKey:@"ShowIcon"] intValue] != 1)
                fail([@"boolean " stringByAppendingString:v], @1, [s objectForKey:@"ShowIcon"]);
        }
        for (NSString *v in @[@"false", @"no", @"off", @"0"]) {
            s = parse([NSString stringWithFormat:@"[general]\nshow-menu-bar-icon = %@\n", v]);
            if ([[s objectForKey:@"ShowIcon"] intValue] != 0)
                fail([@"boolean " stringByAppendingString:v], @0, [s objectForKey:@"ShowIcon"]);
        }

        // Comments and blank lines must not produce bindings.
        s = parse(@"# comment\n\n[mouse]\nhold-middle-tap-index = return # trailing\n");
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

        if (failures == 0) {
            printf("config parser: all checks passed\n");
            return 0;
        }
        fprintf(stderr, "config parser: %d failure(s)\n", failures);
        return 1;
    }
}
