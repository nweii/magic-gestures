//
//  Config.h
//  MagicGestures
//
//  Copyright 2026 Nathan Cheng. All rights reserved.
//
//  Reads the text configuration file and produces the settings dictionary the
//  vendored engine already consumes, so nothing downstream needs to know the
//  configuration stopped being a plist.
//

#import <Foundation/Foundation.h>

@interface Config : NSObject

// ~/.config/magic-gestures/config.txt, or the path in MAGICGESTURES_CONFIG.
// Returns nil when no configuration file exists.
+ (NSString *)resolvedPath;

// ~/.config/magic-gestures, where the configuration and its agent notes live.
+ (NSString *)configDirectory;

// Parses the file at `path` into a settings dictionary shaped like the plist
// that Settings loadSettings2: expects. Returns nil if the file cannot be read.
// Unparseable lines are skipped rather than failing the whole file.
+ (NSDictionary *)settingsFromFile:(NSString *)path;

// As above, and fills outProblems with a description of every line that was
// skipped. Lines are skipped rather than failing the file, so this is the only
// way a caller learns a binding did not take.
+ (NSDictionary *)settingsFromFile:(NSString *)path problems:(NSArray **)outProblems;

// Every gesture slug the configuration accepts, mapped to the engine gesture
// names it binds. One slug can bind several names where the engine splits a
// single motion into variants a person would not distinguish.
+ (NSDictionary *)mouseGestureSlugs;
+ (NSDictionary *)trackpadGestureSlugs;

// An engine gesture name phrased as a motion, for display.
+ (NSString *)humanNameForGesture:(NSString *)raw;

@end
