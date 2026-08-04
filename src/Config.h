//
//  Config.h
//  Trickpad
//
//  Copyright 2026 Nathan Cheng. All rights reserved.
//
//  Reads the TOML configuration file and produces the settings dictionary the
//  vendored engine already consumes, so nothing downstream needs to know the
//  configuration stopped being a plist.
//

#import <Foundation/Foundation.h>

@interface Config : NSObject

// ~/.config/trickpad/config.toml, or the path in TRICKPAD_CONFIG. The former
// MAGICGESTURES_CONFIG name remains an undocumented pre-release fallback.
// Returns nil when no configuration file exists.
+ (NSString *)resolvedPath;

// ~/.config/trickpad, where the configuration and its agent notes live.
+ (NSString *)configDirectory;

// Parses the file at `path` into a settings dictionary shaped like the plist
// that Settings loadSettings2: expects. Returns nil if the file cannot be read
// or is invalid TOML. Schema errors are reported and skipped individually.
+ (NSDictionary *)settingsFromFile:(NSString *)path;

// As above, and fills outProblems with TOML or schema diagnostics. Invalid TOML
// returns nil; recognized schema errors are reported while valid bindings load.
+ (NSDictionary *)settingsFromFile:(NSString *)path problems:(NSArray **)outProblems;

// Resolves the supported substitutions in a URL binding. Explicit clipboard
// and date inputs keep resolution deterministic for parser checks.
+ (NSString *)URLByResolvingSubstitutions:(NSString *)url
                                clipboard:(NSString *)clipboard
                                     date:(NSDate *)date
                                  problem:(NSString **)outProblem;

// Every gesture slug the configuration accepts, mapped to the engine gesture
// names it binds. One slug can bind several names where the engine splits a
// single motion into variants a person would not distinguish.
+ (NSDictionary *)mouseGestureSlugs;
+ (NSDictionary *)trackpadGestureSlugs;

// Returns the first engine name for the public slug containing raw, so aliases
// can be presented as one configured gesture.
+ (NSString *)canonicalGestureName:(NSString *)raw inSlugs:(NSDictionary *)slugs;

// Every action slug the configuration accepts, mapped to the engine command
// string it dispatches.
+ (NSDictionary *)actionNames;

// An engine gesture name phrased as a motion, for display.
+ (NSString *)humanNameForGesture:(NSString *)raw;

@end
