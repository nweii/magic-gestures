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

- (void)showIcon {
    theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];

    if (enAll)
        [theMenu insertItemWithTitle:@"Turn MagicGestures Off" action:@selector(switchChange:) keyEquivalent:@"" atIndex:0];
    else
        [theMenu insertItemWithTitle:@"Turn MagicGestures On" action:@selector(switchChange:) keyEquivalent:@"" atIndex:0];

    //[theMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
    [theMenu insertItemWithTitle:@"Reveal Bindings File..." action:@selector(preferences:) keyEquivalent:@"" atIndex:1];
    [theMenu insertItem:[NSMenuItem separatorItem] atIndex:2];
    [theMenu insertItemWithTitle:@"Quit MagicGestures" action:@selector(quit:) keyEquivalent:@"" atIndex:3];

    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [theItem retain];
    [self updateIconImage];
    [theItem setHighlightMode:YES];
    [theItem setMenu:theMenu];
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
    [theItem setImage:img];
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


- (void)quit:(id)sender {
    [self unloadJitouchLaunchAgent];

    // Quit
    [NSApp terminate: sender];
}

- (void)refreshMenu {
    if (theItem == nil && [[settings objectForKey:@"ShowIcon"] intValue] == 1){
        [self showIcon];
    } else if (theItem != nil && [[settings objectForKey:@"ShowIcon"] intValue] == 0){
        [self hideIcon];
    }
    if (theItem) {
        if (enAll) {
            [[theMenu itemAtIndex:0] setTitle:@"Turn MagicGestures Off"];
        } else {
            [[theMenu itemAtIndex:0] setTitle:@"Turn MagicGestures On"];
        }
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
