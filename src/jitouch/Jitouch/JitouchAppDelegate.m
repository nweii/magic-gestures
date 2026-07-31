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
#include <pwd.h>
#include <unistd.h>

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

// Menu items are found by tag rather than index so the layout can change
// without breaking the code that updates their titles and check marks.
enum {
    kMenuTagToggle = 1,
    kMenuTagLoginItem = 2,
    kMenuTagAccessibility = 3,
    kMenuTagBindings = 4,
    kMenuTagAgents = 5,
};

// The prompt handed to whichever coding agent the user picks. It points at the
// two documents that explain the binding vocabulary, so the agent does not have
// to rediscover them.
static NSString *const kAgentPrompt =
    @"Read AGENTS.md and GESTURES.md first. Help me change my MagicGestures "
    @"gesture bindings, or troubleshoot the setup. Ask me what I want before "
    @"editing generate_config.py, then apply it with Reload Configuration.";

static NSString *shellQuote(NSString *s) {
    NSString *escaped = [s stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    return [NSString stringWithFormat:@"'%@'", escaped];
}

// Directories that install scripts commonly write to, checked when the login
// shell turns up nothing. Covers Homebrew on both architectures, the standard
// user-local bin, and the JavaScript runtimes agents often ship through.
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

// The login shell is read from the account record rather than the environment,
// because a launchd-started GUI app inherits neither SHELL nor the user's PATH.
static NSString *loginShellPath(void) {
    struct passwd *pw = getpwuid(getuid());
    if (pw != NULL && pw->pw_shell != NULL) {
        NSString *shell = [NSString stringWithUTF8String:pw->pw_shell];
        if ([[NSFileManager defaultManager] isExecutableFileAtPath:shell])
            return shell;
    }
    return @"/bin/zsh";
}

// Agents install through shell profiles, so they land in places a GUI app's
// PATH never covers. Asking the user's own login shell resolves them the way
// their terminal would, whatever shell and package manager they use.
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

// Gesture names are written for the configuration file, where precision matters
// more than readability. The menu describes the same motion as a hand does it.
static NSString *humanGestureName(NSString *raw) {
    static NSDictionary *phrases = nil;
    if (phrases == nil) {
        phrases = [@{
            @"Index-Fix Middle-Near-Tap": @"Hold index, tap with middle",
            @"Index-Fix Middle-Far-Tap": @"Hold index, tap wide with middle",
            @"Middle-Fix Index-Near-Tap": @"Hold middle, tap with index",
            @"Middle-Fix Index-Far-Tap": @"Hold middle, tap wide with index",
            @"One-Fix Left-Tap": @"Hold one finger, tap to its left",
            @"One-Fix Right-Tap": @"Hold one finger, tap to its right",
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
        } retain];
    }
    NSString *phrase = [phrases objectForKey:raw];
    return phrase ?: raw;
}

// Every path that needs the checkout resolves it here: the bundle sits in
// build/ inside the project, so the root is two levels up.
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

// PLIST_ONLY keeps the scripts from touching launchd, so toggling this cannot
// restart or terminate the app running the toggle. The change lands at login.
- (void)toggleLoginItem:(id)sender {
    NSString *root = [self projectRoot];
    if (root == nil)
        return;

    NSString *script = [self isLoginItemInstalled] ? @"uninstall-login-agent.sh" : @"install-login-agent.sh";
    NSString *path = [root stringByAppendingPathComponent:[@"scripts" stringByAppendingPathComponent:script]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        return;

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:path];
    NSMutableDictionary *env = [[[[NSProcessInfo processInfo] environment] mutableCopy] autorelease];
    [env setObject:@"1" forKey:@"PLIST_ONLY"];
    [task setEnvironment:env];
    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *e) {
    }
    [task release];

    [self refreshMenu];
}

// Regenerating writes the plist; loadSettings reads it back. The gesture engine
// itself does not need restarting for a binding change.
- (void)reloadConfiguration:(id)sender {
    NSString *root = [self projectRoot];
    NSString *generator = root ? [root stringByAppendingPathComponent:@"generate_config.py"] : nil;

    if (generator != nil && [[NSFileManager defaultManager] fileExistsAtPath:generator]) {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/env"];
        [task setArguments:@[@"python3", generator]];
        [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
        @try {
            [task launch];
            [task waitUntilExit];
        } @catch (NSException *e) {
        }
        [task release];
    }

    [Settings loadSettings];
    [self refreshMenu];
    if (!enAll)
        turnOffGestures();
}

- (void)about:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/nweii/magic-gestures"]];
}

- (void)openAccessibilitySettings:(id)sender {
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

// Without this grant the event tap never starts and every gesture silently does
// nothing, so the state is worth showing rather than leaving to the log.
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

// Reading the bindings back from the loaded settings means the menu cannot drift
// from what the engine is actually matching against.
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
                NSString *command = [g objectForKey:@"Command"];
                if (gesture == nil || command == nil)
                    continue;
                [lines addObject:[NSString stringWithFormat:@"%@  →  %@", humanGestureName(gesture), command]];
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

// Configuring by hand means editing Python. Handing the job to an agent that has
// already been told where the vocabulary is documented is the lighter path, and
// the same session covers troubleshooting.
- (void)configureWithAgent:(id)sender {
    NSString *agentPath = [sender representedObject];
    NSString *root = [self projectRoot];
    if (agentPath == nil || root == nil)
        return;

    NSString *runDir = [root stringByAppendingPathComponent:@"run"];
    [[NSFileManager defaultManager] createDirectoryAtPath:runDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];

    NSString *scriptPath = [runDir stringByAppendingPathComponent:@"configure-with-agent.command"];
    NSString *script = [NSString stringWithFormat:
        @"#!/bin/zsh\ncd %@\nexec %@ %@\n",
        shellQuote(root), shellQuote(agentPath), shellQuote(kAgentPrompt)];

    NSError *err = nil;
    if (![script writeToFile:scriptPath atomically:YES encoding:NSUTF8StringEncoding error:&err])
        return;

    [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @(0755)}
                                     ofItemAtPath:scriptPath
                                            error:NULL];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:scriptPath]];
}

- (NSMenu *)buildAgentSubmenu {
    NSMenu *sub = [[[NSMenu alloc] initWithTitle:@"Change Gestures with Agent"] autorelease];
    // Rebuilt each time it opens, so an agent installed after launch appears
    // without restarting. Probing costs a login shell per candidate, which is
    // why it happens on demand rather than on every menu open.
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

        NSMenuItem *hint = [menu addItemWithTitle:@"Change Gestures by Hand..." action:@selector(preferences:) keyEquivalent:@""];
        [hint setTarget:self];

        NSMenuItem *docs = [menu addItemWithTitle:@"Read the Setup Guide..." action:@selector(about:) keyEquivalent:@""];
        [docs setTarget:self];
    }
}

- (void)showIcon {
    theMenu = [[[NSMenu alloc] initWithTitle:@"MagicGestures"] autorelease];

    NSMenuItem *item = [theMenu addItemWithTitle:@"Turn MagicGestures Off" action:@selector(switchChange:) keyEquivalent:@""];
    [item setTag:kMenuTagToggle];

    item = [theMenu addItemWithTitle:@"Accessibility" action:NULL keyEquivalent:@""];
    [item setTag:kMenuTagAccessibility];
    [item setTarget:self];

    [theMenu addItem:[NSMenuItem separatorItem]];

    item = [theMenu addItemWithTitle:@"Current Gestures" action:NULL keyEquivalent:@""];
    [item setTag:kMenuTagBindings];

    [theMenu addItem:[NSMenuItem separatorItem]];

    item = [theMenu addItemWithTitle:@"Change Gestures with Agent" action:NULL keyEquivalent:@""];
    [item setTag:kMenuTagAgents];
    [item setSubmenu:[self buildAgentSubmenu]];

    [theMenu addItemWithTitle:@"Change Gestures by Hand..." action:@selector(preferences:) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Reload Gestures" action:@selector(reloadConfiguration:) keyEquivalent:@""];

    item = [theMenu addItemWithTitle:@"Open at Login" action:@selector(toggleLoginItem:) keyEquivalent:@""];
    [item setTag:kMenuTagLoginItem];

    [theMenu addItem:[NSMenuItem separatorItem]];
    [theMenu addItemWithTitle:@"About MagicGestures" action:@selector(about:) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Quit MagicGestures" action:@selector(quit:) keyEquivalent:@""];

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
}

// A system symbol rather than bundled artwork, so the menu bar item carries no
// borrowed branding. Filled reads as active, outlined as suspended.
- (void)updateIconImage {
    NSString *symbol = enAll ? @"hand.tap.fill" : @"hand.tap";
    NSImage *img = [NSImage imageWithSystemSymbolName:symbol
                             accessibilityDescription:@"MagicGestures"];
    [img setTemplate:YES];
    // The button, rather than the status item itself: setImage: and
    // setHighlightMode: on NSStatusItem have been deprecated since 10.14.
    [[theItem button] setImage:img];
}

- (void)preferences:(id)sender  {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSString *projectRoot = nil;
    if (bundlePath != nil && [bundlePath length] > 0) {
        NSString *buildRoot = [bundlePath stringByDeletingLastPathComponent];
        projectRoot = [[buildRoot stringByDeletingLastPathComponent] stringByStandardizingPath];
    }

    // Reveal the file bindings are actually edited in, rather than the
    // generated output beside it.
    NSString *sourcePath = projectRoot ? [projectRoot stringByAppendingPathComponent:@"generate_config.py"] : nil;
    if (sourcePath != nil && [[NSFileManager defaultManager] fileExistsAtPath:sourcePath]) {
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[[NSURL fileURLWithPath:sourcePath]]];
        return;
    }

    NSString *openPath = projectRoot;
    if (openPath != nil && [[NSFileManager defaultManager] fileExistsAtPath:openPath]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:openPath]];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Can't find the MagicGestures config folder."];
        [alert setInformativeText:@"Please relaunch MagicGestures from the repository checkout."];
        [alert setAlertStyle:NSAlertStyleWarning];
        [NSApp activateIgnoringOtherApps:YES];
        [alert runModal];
        [alert release];
    }
}


// Quitting has to stop the launchd job, or KeepAlive restarts the process
// immediately. That makes it a one-way trip from the menu, so say how to get
// back when nothing is going to bring it back on its own.
- (void)quit:(id)sender {
    if (![self isLoginItemInstalled]) {
        NSString *root = [self projectRoot];
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"Quit MagicGestures?"];
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
        [toggle setTitle:enAll ? @"Turn MagicGestures Off" : @"Turn MagicGestures On"];

        NSMenuItem *login = [theMenu itemWithTag:kMenuTagLoginItem];
        [login setState:[self isLoginItemInstalled] ? NSControlStateValueOn : NSControlStateValueOff];

        [self refreshAccessibilityItem];
        [self refreshBindingsSubmenu];
        [self updateIconImage];
    }
}

- (void)switchChange:(id)sender {
    enAll = !enAll;
    [self refreshMenu];
    [self saveSettings];

    if (!enAll)
        turnOffGestures();
}

#pragma mark - Settings

- (void)saveSettings {
    [Settings setKey:@"enAll" withInt:enAll];
    [Settings noteSettingsUpdated2];
}

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
    [Settings loadSettings];

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
    [super dealloc];
}

@end
