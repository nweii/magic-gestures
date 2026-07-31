//
//  JitouchAppDelegate.m
//  Jitouch
//
//  Copyright 2021 Supasorn Suwajanakorn and Sukolsak Sakshuwong. All rights reserved.
//  Modified work Copyright 2021 Aaron Kollasch. All rights reserved.
//  Modified work Copyright 2026 Nathan Cheng. All rights reserved.
//

#import "JitouchAppDelegate.h"
#import "Settings.h"
#import "Gesture.h"
#import "CursorWindow.h"
#import <Carbon/Carbon.h>
#import <CoreFoundation/CFPreferences.h>
#import "SystemPreferences.h"
#import "Config.h"
#import "KeyUtility.h"
#include <pwd.h>
#include <unistd.h>

static NSArray *lastConfigProblems = nil;

CursorWindow *cursorWindow;
CGKeyCode keyMap[128]; // for dvorak support

@implementation JitouchAppDelegate

@synthesize window;

- (void)unloadJitouchLaunchAgent {
    NSString *plistPath = [@"~/Library/LaunchAgents/fyi.nathancheng.magic-gestures.agent.plist" stringByStandardizingPath];
    NSArray *unloadArgs = [NSArray arrayWithObjects:@"unload",
                           plistPath,
                           nil];
    NSTask *unloadTask = [NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" arguments:unloadArgs];
    [unloadTask waitUntilExit];
}

#pragma mark - Menu

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    return YES;
}

// Tags identify menu items whose titles or check marks are updated after the
// menu is created.
enum {
    kMenuTagToggle = 1,
    kMenuTagLoginItem = 2,
    kMenuTagAccessibility = 3,
    kMenuTagBindings = 4,
    kMenuTagAgents = 5,
    kMenuTagProblems = 6,
};

// This prompt tells the selected coding agent where to find the binding
// vocabulary and how to apply configuration changes.
static NSString *const kAgentPrompt =
    @"Read AGENTS.md in this folder first. Help me change my Magic Gestures "
    @"gestures. Ask me what I want before editing config.txt, then tell me to "
    @"pick \"Reload Settings\" from the menu bar.";

static NSString *shellQuote(NSString *s) {
    NSString *escaped = [s stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    return [NSString stringWithFormat:@"'%@'", escaped];
}

// These directories are checked when the login shell cannot find a tool. They
// cover Homebrew on both architectures, user-local binaries, and common
// JavaScript runtime installers.
static NSArray *fallbackToolDirectories(void) {
    NSString *home = NSHomeDirectory();
    return @[[home stringByAppendingPathComponent:@".local/bin"],
             @"/opt/homebrew/bin",
             @"/usr/local/bin",
             @"/usr/bin",
             [home stringByAppendingPathComponent:@".bun/bin"],
             [home stringByAppendingPathComponent:@".deno/bin"],
             [home stringByAppendingPathComponent:@".cargo/bin"],
             [home stringByAppendingPathComponent:@".volta/bin"],
             [home stringByAppendingPathComponent:@".npm-global/bin"],
             [home stringByAppendingPathComponent:@".yarn/bin"],
             [home stringByAppendingPathComponent:@"bin"]];
}

// A launchd-started GUI app does not inherit SHELL or the user's PATH, so the
// login shell is read from the account record.
static NSString *loginShellPath(void) {
    struct passwd *pw = getpwuid(getuid());
    if (pw != NULL && pw->pw_shell != NULL) {
        NSString *shell = [NSString stringWithUTF8String:pw->pw_shell];
        if ([[NSFileManager defaultManager] isExecutableFileAtPath:shell])
            return shell;
    }
    return @"/bin/zsh";
}

// Coding agents may be installed through shell profiles outside a GUI app's
// PATH. The user's login shell resolves them with the same shell and package
// manager paths available in a terminal.
static NSString *resolveToolPath(NSString *tool) {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:loginShellPath()];
    [task setArguments:@[@"-lc", [NSString stringWithFormat:@"command -v %@", tool]]];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

    NSString *path = nil;
    @try {
        [task launch];
        NSData *out = [[pipe fileHandleForReading] readDataToEndOfFile];
        [task waitUntilExit];
        if ([task terminationStatus] == 0) {
            path = [[[NSString alloc] initWithData:out encoding:NSUTF8StringEncoding] autorelease];
            path = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([path length] == 0)
                path = nil;
        }
    } @catch (NSException *e) {
        path = nil;
    }
    [task release];

    if (path != nil)
        return path;

    for (NSString *dir in fallbackToolDirectories()) {
        NSString *candidate = [dir stringByAppendingPathComponent:tool];
        if ([[NSFileManager defaultManager] isExecutableFileAtPath:candidate])
            return candidate;
    }
    return nil;
}

// Describes a binding from its keycode and modifier flags. Labels describe an
// app-dependent purpose and may not match the focused app.
static NSString *describeBinding(NSDictionary *g) {
    if ([[g objectForKey:@"IsAction"] boolValue])
        return [g objectForKey:@"Command"] ?: @"";

    NSUInteger flags = [[g objectForKey:@"ModifierFlags"] unsignedIntegerValue];
    NSMutableString *out = [NSMutableString string];
    if (flags & kCGEventFlagMaskControl)   [out appendString:@"⌃"];
    if (flags & kCGEventFlagMaskAlternate) [out appendString:@"⌥"];
    if (flags & kCGEventFlagMaskShift)     [out appendString:@"⇧"];
    if (flags & kCGEventFlagMaskCommand)   [out appendString:@"⌘"];

    // Keys without a printed character use names instead of the glyphs returned
    // by codeToChar.
    CGKeyCode code = (CGKeyCode)[[g objectForKey:@"KeyCode"] unsignedIntValue];
    NSDictionary *named = @{@36: @"Return", @53: @"Escape", @48: @"Tab",
                            @49: @"Space", @51: @"Delete", @117: @"Forward Delete",
                            @76: @"Enter", @123: @"Left", @124: @"Right",
                            @125: @"Down", @126: @"Up"};
    NSString *key = [named objectForKey:@(code)] ?: [KeyUtility codeToChar:code];
    [out appendString:key ?: @""];
    return out;
}

// The application bundle is in the project's build directory, two levels below
// the project root.
- (NSString *)projectRoot {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    if (bundlePath == nil || [bundlePath length] == 0)
        return nil;
    NSString *buildRoot = [bundlePath stringByDeletingLastPathComponent];
    return [[buildRoot stringByDeletingLastPathComponent] stringByStandardizingPath];
}

- (NSString *)loginAgentPlistPath {
    return [@"~/Library/LaunchAgents/fyi.nathancheng.magic-gestures.agent.plist" stringByStandardizingPath];
}

- (BOOL)isLoginItemInstalled {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self loginAgentPlistPath]];
}

// The menu bar is the only interface, so a menu action that fails says so in an
// alert naming the file or script involved.
- (void)reportFailure:(NSString *)message detail:(NSString *)detail {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:message];
    if ([detail length] > 0)
        [alert setInformativeText:detail];
    [alert setAlertStyle:NSAlertStyleWarning];
    [NSApp activateIgnoringOtherApps:YES];
    [alert runModal];
    [alert release];
}

// PLIST_ONLY changes the login item file without changing the running launchd
// job. The file change takes effect at login.
- (void)toggleLoginItem:(id)sender {
    BOOL installed = [self isLoginItemInstalled];
    NSString *root = [self projectRoot];
    NSString *script = installed ? @"uninstall-login-agent.sh" : @"install-login-agent.sh";
    NSString *path = root ? [root stringByAppendingPathComponent:[@"scripts" stringByAppendingPathComponent:script]] : nil;
    if (path == nil || ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [self reportFailure:@"Can't change Open at Login."
                     detail:[NSString stringWithFormat:@"scripts/%@ is missing from the project folder.", script]];
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:path];
    NSMutableDictionary *env = [[[[NSProcessInfo processInfo] environment] mutableCopy] autorelease];
    [env setObject:@"1" forKey:@"PLIST_ONLY"];
    [task setEnvironment:env];

    NSString *failure = nil;
    @try {
        [task launch];
        [task waitUntilExit];
        int status = [task terminationStatus];
        if (status != 0)
            failure = [NSString stringWithFormat:@"scripts/%@ exited with status %d.", script, status];
    } @catch (NSException *e) {
        failure = [NSString stringWithFormat:@"scripts/%@ could not be run. %@", script, [e reason]];
    }
    [task release];

    // The script can stop partway and leave the plist half written, so the
    // resulting state is read back from disk instead of assumed.
    if (failure == nil && [self isLoginItemInstalled] == installed)
        failure = [NSString stringWithFormat:@"scripts/%@ finished, but the login item is still %@.",
                   script, installed ? @"in place" : @"missing"];

    [self refreshMenu];

    if (failure != nil)
        [self reportFailure:@"Can't change Open at Login." detail:failure];
}

// Reads the configuration file and applies it to the running gesture engine.
// The previous configuration stays in effect when the file cannot be read.
- (void)reloadConfiguration:(id)sender {
    NSString *path = [Config resolvedPath];
    if (path == nil) {
        [self reportFailure:@"No configuration file found."
                     detail:[NSString stringWithFormat:@"Expected it at %@/config.txt. Nothing changed.",
                             [Config configDirectory]]];
        return;
    }

    NSArray *problems = nil;
    NSDictionary *parsed = [Config settingsFromFile:path problems:&problems];
    if (parsed == nil) {
        [self reportFailure:@"Could not read the configuration."
                     detail:[NSString stringWithFormat:@"%@ could not be opened. Nothing changed.", path]];
        return;
    }

    [self setConfigProblems:problems];
    [Settings loadSettings2:parsed];
    [self refreshMenu];
    if (!enAll)
        turnOffGestures();

    if ([problems count] > 0)
        [self showConfigProblems:nil];
}

- (void)setConfigProblems:(NSArray *)problems {
    [problems retain];
    [lastConfigProblems release];
    lastConfigProblems = problems;
}

// Skipped lines are the common failure in a hand-edited file, and nothing else
// in the app would show them.
- (void)showConfigProblems:(id)sender {
    if ([lastConfigProblems count] == 0)
        return;

    NSString *body = [lastConfigProblems componentsJoinedByString:@"\n\n"];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:[NSString stringWithFormat:@"%lu line%@ skipped in config.txt",
                           (unsigned long)[lastConfigProblems count],
                           [lastConfigProblems count] == 1 ? @"" : @"s"]];
    [alert setInformativeText:[NSString stringWithFormat:@"%@\n\nEverything else was applied.", body]];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Edit Settings..."];
    [NSApp activateIgnoringOtherApps:YES];
    NSModalResponse r = [alert runModal];
    [alert release];
    if (r == NSAlertSecondButtonReturn)
        [self preferences:nil];
}

- (void)about:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/nweii/magic-gestures"]];
}

- (void)openAccessibilitySettings:(id)sender {
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

// The event tap requires Accessibility access. The menu shows whether the
// process has this access because gestures do nothing without it.
- (void)refreshAccessibilityItem {
    NSMenuItem *item = [theMenu itemWithTag:kMenuTagAccessibility];
    if (item == nil)
        return;

    if (AXIsProcessTrusted()) {
        [item setTitle:@"Accessibility access granted"];
        [item setAction:NULL];
    } else {
        [item setTitle:@"Accessibility access needed..."];
        [item setAction:@selector(openAccessibilitySettings:)];
    }
}

// The submenu reads bindings from the settings used by the gesture engine.
- (void)refreshProblemsItem {
    NSMenuItem *item = [theMenu itemWithTag:kMenuTagProblems];
    if (item == nil)
        return;

    NSUInteger n = [lastConfigProblems count];
    if (n == 0) {
        [item setTitle:@"Configuration loaded"];
        [item setAction:NULL];
    } else {
        [item setTitle:[NSString stringWithFormat:@"%lu line%@ skipped in config.txt...",
                        (unsigned long)n, n == 1 ? @"" : @"s"]];
        [item setAction:@selector(showConfigProblems:)];
    }
}

- (void)refreshBindingsSubmenu {
    NSMenuItem *parent = [theMenu itemWithTag:kMenuTagBindings];
    if (parent == nil)
        return;

    NSMenu *sub = [[[NSMenu alloc] initWithTitle:@"Current Gestures"] autorelease];
    NSArray *sources = @[@[@"Mouse", magicMouseCommands ?: @[]],
                         @[@"Trackpad", trackpadCommands ?: @[]]];
    BOOL any = NO;

    for (NSArray *pair in sources) {
        NSMutableArray *lines = [NSMutableArray array];
        for (NSDictionary *app in pair[1]) {
            for (NSDictionary *g in [app objectForKey:@"Gestures"]) {
                NSString *gesture = [g objectForKey:@"Gesture"];
                if (gesture == nil)
                    continue;
                NSString *fires = describeBinding(g);
                if ([fires length] == 0)
                    continue;
                [lines addObject:[NSString stringWithFormat:@"%@  →  %@", [Config humanNameForGesture:gesture], fires]];
            }
        }
        if ([lines count] == 0)
            continue;

        if (any)
            [sub addItem:[NSMenuItem separatorItem]];
        any = YES;

        NSMenuItem *header = [sub addItemWithTitle:pair[0] action:NULL keyEquivalent:@""];
        [header setEnabled:NO];
        for (NSString *line in lines) {
            NSMenuItem *row = [sub addItemWithTitle:line action:NULL keyEquivalent:@""];
            [row setEnabled:NO];
            [row setIndentationLevel:1];
        }
    }

    if (!any) {
        NSMenuItem *empty = [sub addItemWithTitle:@"Nothing configured yet" action:NULL keyEquivalent:@""];
        [empty setEnabled:NO];
    }

    [parent setSubmenu:sub];
}

// Starts the selected coding agent in the project with instructions for editing
// and troubleshooting the gesture configuration.
- (void)configureWithAgent:(id)sender {
    NSString *agentPath = [sender representedObject];
    if (agentPath == nil)
        return;

    NSString *dir = [Config configDirectory];
    NSError *error = [self seedConfigDirectory];
    if (error != nil) {
        [self reportFailure:@"Can't set up the Magic Gestures settings folder."
                     detail:[error localizedDescription]];
        return;
    }

    NSString *scriptPath = [dir stringByAppendingPathComponent:@"configure-with-agent.command"];
    NSString *script = [NSString stringWithFormat:
        @"#!/bin/zsh\ncd %@\nexec %@ %@\n",
        shellQuote(dir), shellQuote(agentPath), shellQuote(kAgentPrompt)];

    if (![script writeToFile:scriptPath atomically:YES encoding:NSUTF8StringEncoding error:&error] ||
        ![[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @(0755)}
                                          ofItemAtPath:scriptPath
                                                 error:&error]) {
        [self reportFailure:@"Can't start the coding agent." detail:[error localizedDescription]];
        return;
    }

    if (![[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:scriptPath]])
        [self reportFailure:@"Can't start the coding agent."
                     detail:[NSString stringWithFormat:@"Nothing opened %@.", scriptPath]];
}

// Creates the configuration folder and fills it from the shipped defaults when
// a file is missing. Existing files are left alone. Returns the error that
// stopped it, or nil once the folder is ready.
- (NSError *)seedConfigDirectory {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = [Config configDirectory];
    NSError *error = nil;
    if (![fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error])
        return error;

    NSString *root = [self projectRoot];
    NSArray *pairs = @[@[@"config.default.txt", @"config.txt"],
                       @[@"config-notes.default.md", @"AGENTS.md"]];
    for (NSArray *pair in pairs) {
        NSString *dst = [dir stringByAppendingPathComponent:pair[1]];
        if ([fm fileExistsAtPath:dst])
            continue;
        NSString *src = root ? [root stringByAppendingPathComponent:pair[0]] : nil;
        if (src == nil || ![fm fileExistsAtPath:src])
            continue;
        if (![fm copyItemAtPath:src toPath:dst error:&error])
            return error;
    }
    return nil;
}

- (NSMenu *)buildAgentSubmenu {
    NSMenu *sub = [[[NSMenu alloc] initWithTitle:@"Change Settings with Agent"] autorelease];
    // The delegate rebuilds this submenu when it opens. Each candidate requires
    // a login-shell probe, and tools installed after launch are included.
    [sub setDelegate:self];
    return sub;
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    NSMenuItem *agents = [theMenu itemWithTag:kMenuTagAgents];
    if (menu != [agents submenu])
        return;

    [menu removeAllItems];

    NSArray *candidates = @[@[@"Claude Code", @"claude"],
                            @[@"Codex", @"codex"],
                            @[@"Cursor", @"cursor-agent"],
                            @[@"Gemini", @"gemini"],
                            @[@"opencode", @"opencode"],
                            @[@"Aider", @"aider"]];
    BOOL any = NO;

    for (NSArray *pair in candidates) {
        NSString *path = resolveToolPath(pair[1]);
        if (path == nil)
            continue;
        any = YES;
        NSMenuItem *item = [menu addItemWithTitle:pair[0]
                                           action:@selector(configureWithAgent:)
                                    keyEquivalent:@""];
        [item setRepresentedObject:path];
        [item setTarget:self];
        [item setToolTip:path];
    }

    if (!any) {
        NSMenuItem *empty = [menu addItemWithTitle:@"No coding agent installed" action:NULL keyEquivalent:@""];
        [empty setEnabled:NO];

        NSMenuItem *hint = [menu addItemWithTitle:@"Edit Settings..." action:@selector(preferences:) keyEquivalent:@""];
        [hint setTarget:self];

        NSMenuItem *docs = [menu addItemWithTitle:@"Read the Setup Guide..." action:@selector(about:) keyEquivalent:@""];
        [docs setTarget:self];
    }
}

- (void)showIcon {
    // The menu outlives this method and is read back by tag on every refresh,
    // so it is owned here rather than left to the status item.
    theMenu = [[NSMenu alloc] initWithTitle:@"Magic Gestures"];

    NSMenuItem *item = [theMenu addItemWithTitle:@"Turn Magic Gestures Off" action:@selector(switchChange:) keyEquivalent:@""];
    [item setTag:kMenuTagToggle];

    item = [theMenu addItemWithTitle:@"Accessibility" action:NULL keyEquivalent:@""];
    [item setTag:kMenuTagAccessibility];
    [item setTarget:self];

    item = [theMenu addItemWithTitle:@"Configuration" action:@selector(showConfigProblems:) keyEquivalent:@""];
    [item setTag:kMenuTagProblems];
    [item setTarget:self];

    [theMenu addItem:[NSMenuItem separatorItem]];

    item = [theMenu addItemWithTitle:@"Current Gestures" action:NULL keyEquivalent:@""];
    [item setTag:kMenuTagBindings];

    [theMenu addItem:[NSMenuItem separatorItem]];

    item = [theMenu addItemWithTitle:@"Change Settings with Agent" action:NULL keyEquivalent:@""];
    [item setTag:kMenuTagAgents];
    [item setSubmenu:[self buildAgentSubmenu]];

    [theMenu addItemWithTitle:@"Edit Settings..." action:@selector(preferences:) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Reload Settings" action:@selector(reloadConfiguration:) keyEquivalent:@""];

    item = [theMenu addItemWithTitle:@"Open at Login" action:@selector(toggleLoginItem:) keyEquivalent:@""];
    [item setTag:kMenuTagLoginItem];

    [theMenu addItem:[NSMenuItem separatorItem]];
    [theMenu addItemWithTitle:@"About Magic Gestures" action:@selector(about:) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Quit Magic Gestures" action:@selector(quit:) keyEquivalent:@""];

    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [theItem retain];
    [theItem setMenu:theMenu];
    [self updateIconImage];
    [self refreshAccessibilityItem];
    [self refreshBindingsSubmenu];
}

- (void)hideIcon {
    [[NSStatusBar systemStatusBar] removeStatusItem:theItem];
    [theItem release];
    theItem = nil;
    [theMenu release];
    theMenu = nil;
}

// The system symbol is filled while gestures are active and outlined while they
// are suspended.
- (void)updateIconImage {
    NSString *symbol = enAll ? @"hand.tap.fill" : @"hand.tap";
    NSImage *img = [NSImage imageWithSystemSymbolName:symbol
                             accessibilityDescription:@"Magic Gestures"];
    [img setTemplate:YES];
    // NSStatusItem image methods have been deprecated since macOS 10.14, so the
    // image is set on its button.
    [[theItem button] setImage:img];
}

- (void)preferences:(id)sender  {
    NSError *error = [self seedConfigDirectory];
    if (error != nil) {
        [self reportFailure:@"Can't set up the Magic Gestures settings folder."
                     detail:[error localizedDescription]];
        return;
    }

    NSString *path = [Config resolvedPath];
    if (path == nil) {
        [self reportFailure:@"Can't find the Magic Gestures configuration."
                     detail:[NSString stringWithFormat:@"Expected it at %@/config.txt.", [Config configDirectory]]];
        return;
    }

    if (![[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]])
        [self reportFailure:@"Can't open the Magic Gestures configuration." detail:path];
}

- (void)quit:(id)sender {
    if (![self isLoginItemInstalled]) {
        NSString *root = [self projectRoot];
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"Quit Magic Gestures?"];
        [alert setInformativeText:@"Gestures stop until you start it again. Open at Login is off, so it will not come back by itself.\n\nStart it later by opening MagicGestures.app in the build folder, or by running scripts/start.sh."];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert addButtonWithTitle:@"Quit"];
        [alert addButtonWithTitle:@"Cancel"];
        if (root != nil)
            [alert addButtonWithTitle:@"Show Me the Folder"];

        [NSApp activateIgnoringOtherApps:YES];
        NSModalResponse response = [alert runModal];

        if (response == NSAlertSecondButtonReturn)
            return;
        if (response == NSAlertThirdButtonReturn && root != nil) {
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:
                @[[NSURL fileURLWithPath:[root stringByAppendingPathComponent:@"build/MagicGestures.app"]]]];
            return;
        }
    }

    [self unloadJitouchLaunchAgent];
    [NSApp terminate:sender];
}

- (void)refreshMenu {
    if (theItem == nil && [[settings objectForKey:@"ShowIcon"] intValue] == 1){
        [self showIcon];
    } else if (theItem != nil && [[settings objectForKey:@"ShowIcon"] intValue] == 0){
        [self hideIcon];
    }
    if (theItem) {
        NSMenuItem *toggle = [theMenu itemWithTag:kMenuTagToggle];
        [toggle setTitle:enAll ? @"Turn Magic Gestures Off" : @"Turn Magic Gestures On"];

        NSMenuItem *login = [theMenu itemWithTag:kMenuTagLoginItem];
        [login setState:[self isLoginItemInstalled] ? NSControlStateValueOn : NSControlStateValueOff];

        [self refreshAccessibilityItem];
        [self refreshProblemsItem];
        [self refreshBindingsSubmenu];
        [self updateIconImage];
    }
}

// The configuration file has no field for this switch and every load turns
// gestures back on, so the switch lasts until the settings are reloaded or the
// app restarts.
- (void)switchChange:(id)sender {
    enAll = !enAll;
    [self refreshMenu];

    if (!enAll)
        turnOffGestures();
}

#pragma mark - Settings

- (void)settingsUpdated:(NSNotification *)aNotification {
    //[Settings loadSettings];

    [Settings loadSettings2:aNotification.userInfo]; // fixes bug in mountain lion
    [self refreshMenu];

    if (!enAll)
        turnOffGestures();
}

#pragma mark - Initialization


- (void)checkAXAPI {
    AXIsProcessTrustedWithOptions((CFDictionaryRef)@{(id)kAXTrustedCheckOptionPrompt: @(YES)});
}

/*
void languageChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    for (int i = 0; i < 128; i++)
        keyMap[i] = (CGKeyCode)i;
    NSString *inputSource = (NSString*)TISGetInputSourceProperty(TISCopyCurrentKeyboardInputSource(), kTISPropertyLocalizedName);
    if ([inputSource isEqualToString:@"Dvorak"] || [inputSource isEqualToString:@"Svorak"]) {
        keyMap[13] = 43; //w -> ,
        keyMap[12] = 7;  //q -> x
        keyMap[17] = 40; //t -> k
        keyMap[4] = 38;  //h -> j
        keyMap[15] = 31; //r -> o
        keyMap[45] = 37; //n -> l
        keyMap[8] = 34; //c -> i
        keyMap[9] = 47; //v -> >
        keyMap[31] = 1; //o ->
        keyMap[37] = 45; //l -> n
        keyMap[3] = 32; // f -> u
        keyMap[40] = 17;
    } else if ([inputSource isEqualToString:@"French"]) {
        keyMap[13] = 6;  //w -> z
        keyMap[12] = 0;  //q -> a
    }
}
*/

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *configPath = [Config resolvedPath];
    if (configPath != nil) {
        NSArray *problems = nil;
        NSDictionary *parsed = [Config settingsFromFile:configPath problems:&problems];
        [self setConfigProblems:problems];
        if (parsed != nil)
            [Settings loadSettings2:parsed];
    } else {
        [Settings loadSettings];
    }

    [self refreshMenu];

    // Move this task to prefpane instead. Starting at Sierra
    //[self addJitouchToLoginItems];

    // The legacy cursor overlay touches AppKit from gesture callback threads on
    // recent macOS releases and can crash the process. Disable it in the agent.
    cursorWindow = nil;

    //languageChanged(NULL, NULL, NULL, NULL, NULL);

    gesture = [[Gesture alloc] init];

    //[self showIcon];

    [self checkAXAPI];

    [[NSDistributedNotificationCenter defaultCenter] addObserver: self
                                                        selector: @selector(settingsUpdated:)
                                                            name: @"My Notification"
                                                          object: @"fyi.nathancheng.magic-gestures.PrefpaneTarget"];

    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(wokeUp:) name:NSWorkspaceDidWakeNotification object: NULL];

    //CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), self, languageChanged, kTISNotifySelectedKeyboardInputSourceChanged, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)wokeUp:(NSNotification *)aNotification {
    NSLog(@"Woke up.");
    [self reload];
}

- (void)reload {
    [gesture reload];
}

#pragma mark -

- (void) dealloc {
    [cursorWindow release];
    [gesture release];
    [theItem release];
    [theMenu release];
    [super dealloc];
}

@end
