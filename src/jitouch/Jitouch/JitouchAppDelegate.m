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
#include <fcntl.h>

static NSArray *lastConfigProblems = nil;
static dispatch_source_t configWatcher = nil;
static int configWatcherFD = -1;

CursorWindow *cursorWindow;
CGKeyCode keyMap[128]; // for dvorak support

@implementation JitouchAppDelegate

@synthesize window;

// The launchd job that starts the app at login.
static NSString *const kLoginAgentLabel = @"fyi.nathancheng.magic-gestures.agent";
static NSString *const kLoginAgentPlistPath = @"~/Library/LaunchAgents/fyi.nathancheng.magic-gestures.agent.plist";
static NSString *const kDidChooseLoginItem = @"DidChooseLoginItem";

// Removes the launchd job by label rather than plist path, so a job whose
// plist has already been deleted still stops instead of being respawned by
// KeepAlive after quit.
- (void)unloadJitouchLaunchAgent {
    NSString *target = [NSString stringWithFormat:@"gui/%d/%@", (int)getuid(), kLoginAgentLabel];
    NSArray *unloadArgs = [NSArray arrayWithObjects:@"bootout",
                           target,
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
    NSString *url = [g objectForKey:@"OpenURL"];
    if ([url length] > 0) {
        const NSUInteger maxLength = 52;
        NSString *shown = [url length] > maxLength
            ? [[url substringToIndex:maxLength - 1] stringByAppendingString:@"…"]
            : url;
        return [@"Open " stringByAppendingString:shown];
    }
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

// Two levels above the bundle, which is the project root when the app was built
// from a source checkout into its build directory. Anywhere else the path is
// meaningless and its contents are absent.
- (NSString *)projectRoot {
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    if (bundlePath == nil || [bundlePath length] == 0)
        return nil;
    NSString *buildRoot = [bundlePath stringByDeletingLastPathComponent];
    return [[buildRoot stringByDeletingLastPathComponent] stringByStandardizingPath];
}

- (NSString *)loginAgentPlistPath {
    return [kLoginAgentPlistPath stringByStandardizingPath];
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

// Runs launchctl and returns YES when it exits cleanly. Failures are ignored by
// callers that only need a best effort.
static BOOL runLaunchctl(NSArray *arguments) {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/launchctl"];
    [task setArguments:arguments];
    [task setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
    [task setStandardError:[NSFileHandle fileHandleWithNullDevice]];

    BOOL ok = NO;
    @try {
        [task launch];
        [task waitUntilExit];
        ok = ([task terminationStatus] == 0);
    } @catch (NSException *e) {
        ok = NO;
    }
    [task release];
    return ok;
}

// The launchd job runs the executable of whichever copy of the app wrote the
// plist, so the login item follows the app wherever it is installed.
- (NSString *)loginAgentPlistContents {
    NSString *executable = [[NSBundle mainBundle] executablePath];
    if (executable == nil)
        return nil;
    NSString *escaped = [[executable stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"]
                         stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    return [NSString stringWithFormat:
        @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        @"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        @"<!--\n"
        @"  Magic Gestures maps Magic Mouse and Magic Trackpad gestures to keystrokes.\n"
        @"\n"
        @"  This file starts it at login and restarts it if it exits. It is written by\n"
        @"  the app's own Open at Login menu item. Deleting it stops the agent from\n"
        @"  starting at login and leaves the app itself untouched.\n"
        @"-->\n"
        @"<plist version=\"1.0\">\n"
        @"<dict>\n"
        @"  <key>Label</key>\n"
        @"  <string>%@</string>\n"
        @"  <key>ProgramArguments</key>\n"
        @"  <array>\n"
        @"    <string>%@</string>\n"
        @"  </array>\n"
        @"  <key>RunAtLoad</key>\n"
        @"  <true/>\n"
        @"  <key>KeepAlive</key>\n"
        @"  <true/>\n"
        @"  <key>ProcessType</key>\n"
        @"  <string>Interactive</string>\n"
        @"</dict>\n"
        @"</plist>\n", kLoginAgentLabel, escaped];
}

// Writes or removes the login item plist without changing the running launchd
// job. Returns a description when the requested state could not be reached.
- (NSString *)setLoginItemInstalled:(BOOL)install {
    NSString *plistPath = [self loginAgentPlistPath];
    NSString *guiTarget = [NSString stringWithFormat:@"gui/%d/%@", (int)getuid(), kLoginAgentLabel];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *failure = nil;

    if (!install) {
        // No bootout here: when the app was started by launchd, the job is this
        // process, and booting it out would quit the app mid-toggle. Removing
        // the plist is enough to stop the next login from starting it.
        if (![fm removeItemAtPath:plistPath error:&error])
            failure = [NSString stringWithFormat:@"%@ could not be removed. %@", plistPath, [error localizedDescription]];
    } else {
        NSString *contents = [self loginAgentPlistContents];
        NSString *dir = [plistPath stringByDeletingLastPathComponent];
        if (contents == nil) {
            failure = @"The app could not find its own program to start at login.";
        } else if (![fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error]) {
            failure = [NSString stringWithFormat:@"%@ could not be created. %@", dir, [error localizedDescription]];
        } else if (![contents writeToFile:plistPath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            failure = [NSString stringWithFormat:@"%@ could not be written. %@", plistPath, [error localizedDescription]];
        } else {
            // `launchctl disable` persists across logins, so a previously
            // disabled job would stay disabled without this.
            runLaunchctl(@[@"enable", guiTarget]);
        }
    }

    // Writing or removing the file can stop partway, so the resulting state is
    // read back from disk instead of assumed.
    if (failure == nil && [self isLoginItemInstalled] != install)
        failure = [NSString stringWithFormat:@"The login item is still %@.",
                   install ? @"missing" : @"in place"];

    return failure;
}

// The app is only useful while running, so a fresh installation starts at
// login. Recording the choice separately preserves a later opt-out.
- (void)enableLoginItemOnFirstLaunch {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kDidChooseLoginItem])
        return;

    [defaults setBool:YES forKey:kDidChooseLoginItem];
    [defaults synchronize];

    if (![self isLoginItemInstalled]) {
        NSString *failure = [self setLoginItemInstalled:YES];
        if (failure != nil)
            [self reportFailure:@"Can't turn on Open at Login." detail:failure];
    }
}

// The running process is left alone: bootstrapping the job here would start a
// second copy, and booting it out would terminate this one.
- (void)toggleLoginItem:(id)sender {
    NSString *failure = [self setLoginItemInstalled:![self isLoginItemInstalled]];

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDidChooseLoginItem];

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
        NSString *detail = [problems count] > 0
            ? [[problems componentsJoinedByString:@"\n\n"] stringByAppendingString:@"\n\nNothing changed."]
            : [NSString stringWithFormat:@"%@ could not be opened. Nothing changed.", path];
        [self reportFailure:@"Could not apply the configuration." detail:detail];
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

// Applies the configuration file without reporting skipped lines. A save while
// a line is half-typed would otherwise raise an alert about work in progress.
- (void)applyConfigurationQuietly {
    NSString *path = [Config resolvedPath];
    if (path == nil)
        return;
    NSArray *problems = nil;
    NSDictionary *parsed = [Config settingsFromFile:path problems:&problems];
    if (parsed == nil)
        return;
    [self setConfigProblems:problems];
    [Settings loadSettings2:parsed];
    [self refreshMenu];
    if (!enAll)
        turnOffGestures();
}

// Opening an already-running menu bar app restores its icon. This is the way
// back if the item was hidden and the setting to show it is gone.
- (BOOL)applicationShouldHandleReopen:(NSApplication *)app hasVisibleWindows:(BOOL)flag {
    if (theItem == nil)
        [self showIcon];
    return YES;
}

- (void)startWatchingConfig {
    if (configWatcher != nil)
        return;

    NSString *dir = [Config configDirectory];
    configWatcherFD = open([dir fileSystemRepresentation], O_EVTONLY);
    if (configWatcherFD < 0)
        return;

    configWatcher = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, configWatcherFD,
                                           DISPATCH_VNODE_WRITE | DISPATCH_VNODE_RENAME |
                                           DISPATCH_VNODE_DELETE | DISPATCH_VNODE_ATTRIB,
                                           dispatch_get_main_queue());
    __block dispatch_source_t source = configWatcher;
    dispatch_source_set_event_handler(source, ^{
        // Coalesce the several events one save produces.
        [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                 selector:@selector(applyConfigurationQuietly)
                                                   object:nil];
        [self performSelector:@selector(applyConfigurationQuietly) withObject:nil afterDelay:0.3];
    });
    dispatch_source_set_cancel_handler(source, ^{
        close(configWatcherFD);
        configWatcherFD = -1;
    });
    dispatch_resume(source);
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
    NSArray *sources = @[@[@"Mouse", magicMouseCommands ?: @[], [Config mouseGestureSlugs]],
                         @[@"Trackpad", trackpadCommands ?: @[], [Config trackpadGestureSlugs]]];
    BOOL any = NO;

    for (NSArray *pair in sources) {
        NSMutableArray *lines = [NSMutableArray array];
        for (NSDictionary *app in pair[1]) {
            NSMutableSet *seenGestures = [NSMutableSet set];
            for (NSDictionary *g in [app objectForKey:@"Gestures"]) {
                NSString *gestureName = [g objectForKey:@"Gesture"];
                if (gestureName == nil)
                    continue;
                gestureName = [Config canonicalGestureName:gestureName inSlugs:pair[2]];
                if ([seenGestures containsObject:gestureName])
                    continue;
                NSString *fires = describeBinding(g);
                if ([fires length] == 0)
                    continue;
                [seenGestures addObject:gestureName];
                [lines addObject:[NSString stringWithFormat:@"%@  →  %@", [Config humanNameForGesture:gestureName], fires]];
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

// Starts the selected coding agent in the settings folder with the running app
// path, which distinguishes a source build from a copied release app.
- (void)manageWithAgent:(id)sender {
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

    NSString *appPath = [[NSBundle mainBundle] bundlePath] ?: @"unknown";
    NSString *prompt = [NSString stringWithFormat:
        @"Read AGENTS.md in this folder first. Help me manage Magic Gestures. "
        @"Ask what I want to do before changing settings or the application. "
        @"The running app is at %@.", appPath];
    NSString *scriptPath = [dir stringByAppendingPathComponent:@"manage-with-agent.command"];
    NSString *script = [NSString stringWithFormat:
        @"#!/bin/zsh\ncd %@\nexec %@ %@\n",
        shellQuote(dir), shellQuote(agentPath), shellQuote(prompt)];

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

// Creates the user-owned configuration once and atomically refreshes the
// app-managed agent instructions from the running version.
- (NSError *)seedConfigDirectory {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dir = [Config configDirectory];
    NSError *error = nil;
    if (![fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&error])
        return error;

    NSString *root = [self projectRoot];
    NSString *(^source)(NSString *) = ^(NSString *name) {
        // A source checkout owns the freshest copy even before the app is
        // rebuilt. A copied release app has no matching project-root file and
        // uses the resource carried in its bundle.
        NSString *checkoutSource = root != nil ? [root stringByAppendingPathComponent:name] : nil;
        if (checkoutSource != nil && [fm fileExistsAtPath:checkoutSource])
            return checkoutSource;
        return [[NSBundle mainBundle] pathForResource:[name stringByDeletingPathExtension]
                                               ofType:[name pathExtension]];
    };

    NSString *configPath = [dir stringByAppendingPathComponent:@"config.txt"];
    if (![fm fileExistsAtPath:configPath]) {
        NSString *configSource = source(@"config.default.txt");
        if (configSource != nil && [fm fileExistsAtPath:configSource] &&
            ![fm copyItemAtPath:configSource toPath:configPath error:&error])
            return error;
    }

    NSString *agentSource = source(@"config-notes.default.md");
    if (agentSource != nil && [fm fileExistsAtPath:agentSource]) {
        NSData *instructions = [NSData dataWithContentsOfFile:agentSource];
        NSString *agentPath = [dir stringByAppendingPathComponent:@"AGENTS.md"];
        if (instructions == nil ||
            ![instructions writeToFile:agentPath options:NSDataWritingAtomic error:&error])
            return error ?: [NSError errorWithDomain:@"MagicGestures"
                                                 code:1
                                             userInfo:@{NSLocalizedDescriptionKey:
                                                 @"The installed AGENTS.md could not be refreshed."}];
    }
    return nil;
}

- (NSMenu *)buildAgentSubmenu {
    NSMenu *sub = [[[NSMenu alloc] initWithTitle:@"Manage with Agent"] autorelease];
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
                                           action:@selector(manageWithAgent:)
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

    item = [theMenu addItemWithTitle:@"Manage with Agent" action:NULL keyEquivalent:@""];
    [item setTag:kMenuTagAgents];
    [item setSubmenu:[self buildAgentSubmenu]];

    [theMenu addItemWithTitle:@"Edit Settings..." action:@selector(preferences:) keyEquivalent:@""];
    [theMenu addItemWithTitle:@"Reload Settings" action:@selector(reloadConfiguration:) keyEquivalent:@""];

    item = [theMenu addItemWithTitle:@"Open at Login" action:@selector(toggleLoginItem:) keyEquivalent:@""];
    [item setTag:kMenuTagLoginItem];

    [theMenu addItem:[NSMenuItem separatorItem]];
    NSMenu *aboutMenu = [[[NSMenu alloc] initWithTitle:@"About Magic Gestures"] autorelease];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSMenuItem *versionItem = [aboutMenu addItemWithTitle:
        [NSString stringWithFormat:@"Version %@", version ?: @"unknown"]
                                                  action:NULL keyEquivalent:@""];
    [versionItem setEnabled:NO];
    NSMenuItem *repoItem = [aboutMenu addItemWithTitle:@"GitHub..." action:@selector(about:) keyEquivalent:@""];
    [repoItem setTarget:self];

    NSMenuItem *aboutItem = [theMenu addItemWithTitle:@"About Magic Gestures" action:NULL keyEquivalent:@""];
    [aboutItem setSubmenu:aboutMenu];
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
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"Quit Magic Gestures?"];
        [alert setInformativeText:@"Gestures stop until you start it again. Open at Login is off, so it will not come back by itself.\n\nStart it again by reopening Magic Gestures."];
        [alert setAlertStyle:NSAlertStyleInformational];
        [alert addButtonWithTitle:@"Quit"];
        [alert addButtonWithTitle:@"Cancel"];
        if ([bundlePath length] > 0)
            [alert addButtonWithTitle:@"Show Me the App"];

        [NSApp activateIgnoringOtherApps:YES];
        NSModalResponse response = [alert runModal];

        if (response == NSAlertSecondButtonReturn)
            return;
        if (response == NSAlertThirdButtonReturn && [bundlePath length] > 0) {
            [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:
                @[[NSURL fileURLWithPath:bundlePath]]];
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
    // A zip install has no start.sh or install script to seed the settings
    // folder, so the app seeds it here before resolving the configuration.
    NSError *seedError = [self seedConfigDirectory];
    if (seedError != nil)
        [self reportFailure:@"Can't create the settings folder."
                     detail:[NSString stringWithFormat:@"%@\n\nGestures run with built-in defaults until %@/config.txt exists.",
                             [seedError localizedDescription], [Config configDirectory]]];

    [self enableLoginItemOnFirstLaunch];

    NSString *configPath = [Config resolvedPath];
    if (configPath != nil) {
        NSArray *problems = nil;
        NSDictionary *parsed = [Config settingsFromFile:configPath problems:&problems];
        [self setConfigProblems:problems];
        if (parsed != nil)
            [Settings loadSettings2:parsed];
        else if ([problems count] > 0)
            [self reportFailure:@"Could not apply the configuration."
                         detail:[[problems componentsJoinedByString:@"\n\n"]
                                 stringByAppendingString:@"\n\nBuilt-in defaults are active."]];
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

    [self startWatchingConfig];

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
