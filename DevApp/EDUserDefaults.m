//
//  EDUserDefaults.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDUserDefaults.h"
#import "EDMetrics.h"
#import "EDWildcardPattern.h"

NSString * const EDTabsListViewVisibleDidChangeNotification = @"EDTabsListViewVisibleDidChangeNotification";
NSString * const EDStatusBarVisibleDidChangeNotification = @"EDStatusBarVisibleDidChangeNotification";

NSString * const EDNavigatorViewVisibleDidChangeNotification = @"EDNavigatorViewVisibleDidChangeNotification";
NSString * const EDCanvasViewVisibleDidChangeNotification = @"EDCanvasViewVisibleDidChangeNotification";
NSString * const EDConsoleViewVisibleDidChangeNotification = @"EDConsoleViewVisibleDidChangeNotification";
NSString * const EDDebugLocalVariablesVisibleDidChangeNotification = @"EDDebugLocalVariablesVisibleDidChangeNotification";

NSString * const EDBreakpointsEnabledDidChangeNotification = @"EDBreakpointsEnabledDidChangeNotification";
NSString * const EDBreakpointsDidChangeNotification = @"EDBreakpointsDidChangeNotification";

NSString * const EDSelectedThemeDidChangeNotification = @"EDSelectedThemeDidChangeNotification";

NSString * const EDRulersVisibleDidChangeNotification = @"EDRulersVisibleDidChangeNotification";
NSString * const EDGridVisibleDidChangeNotification = @"EDGridVisibleDidChangeNotification";
NSString * const EDGuidesVisibleDidChangeNotification = @"EDGuidesVisibleDidChangeNotification";
NSString * const EDGuidesLockedDidChangeNotification = @"EDGuidesLockedDidChangeNotification";

NSString * const EDCompositionMetricsDidChangeNotification = @"EDCompositionMetricsDidChangeNotification";
NSString * const EDCompositionZoomScaleDidChangeNotification = @"EDCompositionZoomScaleDidChangeNotification";
NSString * const EDCompositionFlippedDidChangeNotification = @"EDCompositionFlippedDidChangeNotification";
NSString * const EDCompositionGridEnabledDidChangeNotification = @"EDCompositionGridEnabledDidChangeNotification";
NSString * const EDCompositionGridToleranceDidChangeNotification = @"EDCompositionGridToleranceDidChangeNotification";

@interface EDUserDefaults ()
@property (nonatomic, copy, readwrite) NSArray *excludeFilePatterns;
@property (nonatomic, copy) NSString *lastExcludeFilePatternString;
@end

@implementation EDUserDefaults

+ (void)load {
    if ([EDUserDefaults class] == self) {
        @autoreleasepool {
            [self setUpUserDefaults];
        }
    }
}


+ (void)setUpUserDefaults {
    NSBundle *b = [NSBundle bundleForClass:self];
    NSString *path = [b pathForResource:DEFAULT_VALUES_FILENAME ofType:@"plist"];
    NSAssert([path length], @"could not find DefaultValues.plist");
    
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    NSAssert([defaultValues count], @"could not load DefaultValues.plist");
    
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


+ (instancetype)instance {
    return [super instance];
}


- (id)init {
    self = [super init];
    if (self) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(userDefaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.excludeFilePatterns = nil;
    self.lastExcludeFilePatternString = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Notifications

- (void)userDefaultsDidChange:(NSNotification *)n {
    NSString *newStr = self.excludeFilePatternString;
    if (![_lastExcludeFilePatternString isEqualToString:newStr]) {
        [self updateExcludeFilePatternsFromString:newStr];
        self.lastExcludeFilePatternString = newStr;
    }
}


- (void)updateExcludeFilePatternsFromString:(NSString *)fullStr {
    NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    NSArray *strs = [fullStr componentsSeparatedByString:@","];
    
    NSMutableArray *pats = [NSMutableArray arrayWithCapacity:[strs count]];
    
    for (NSString *str in strs) {
        str = [str stringByTrimmingCharactersInSet:cs];
        if ([str length]) {
            EDWildcardPattern *pat = [EDWildcardPattern patternWithString:str];
            [pats addObject:pat];
        }
    }
    
    self.excludeFilePatterns = pats;
}


#pragma mark -
#pragma mark Welcome Window

- (BOOL)showWelcomeWindowOnLaunch {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDShowWelcomeWindowOnLaunchKey];
}
- (void)setShowWelcomeWindowOnLaunch:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDShowWelcomeWindowOnLaunchKey];
}

- (NSString *)documentationHomeURLString {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDDocumentationHomeURLStringKey];
}
- (void)setDocumentationHomeURLString:(NSString *)str {
    [[NSUserDefaults standardUserDefaults] setObject:str forKey:kEDDocumentationHomeURLStringKey];
}

#pragma mark -
#pragma mark UI Bars

- (BOOL)tabsListViewVisible {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDTabsListViewVisibleKey];
}
- (void)setTabsListViewVisible:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDTabsListViewVisibleKey];
}

- (BOOL)statusBarVisible {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDStatusBarVisibleKey];
}
- (void)setStatusBarVisible:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDStatusBarVisibleKey];
}


#pragma mark -
#pragma mark Palettes

- (BOOL)navigatorViewVisible {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDNavigatorViewVisibleKey];
}
- (void)setNavigatorViewVisible:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDNavigatorViewVisibleKey];
}

- (BOOL)canvasViewVisible {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDCanvasViewVisibleKey];
}
- (void)setCanvasViewVisible:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDCanvasViewVisibleKey];
}

- (BOOL)consoleViewVisible {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDConsoleViewVisibleKey];
}
- (void)setConsoleViewVisible:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDConsoleViewVisibleKey];
}

- (BOOL)debugLocalVariablesVisible {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDDebugLocalVariablesVisibleKey];
}
- (void)setDebugLocalVariablesVisible:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDDebugLocalVariablesVisibleKey];
}


#pragma mark -
#pragma mark Document properties

- (BOOL)breakpointsEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDBreakpointsEnabledKey];
}
- (void)setBreakpointsEnabled:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDBreakpointsEnabledKey];
}

#pragma mark -
#pragma mark Canvas

- (BOOL)rulersVisible {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDRulersVisibleKey];
}
- (void)setRulersVisible:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDRulersVisibleKey];
}

- (BOOL)guidesVisible {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDGuidesVisibleKey];
}
- (void)setGuidesVisible:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDGuidesVisibleKey];
}

- (BOOL)guidesLocked {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDGuidesLockedKey];
}
- (void)setGuidesLocked:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDGuidesLockedKey];
}

- (BOOL)isFlipped {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDFlippedKey];
}
- (void)setFlipped:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDFlippedKey];
}

- (BOOL)gridVisible {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDGridVisibleKey];
}
- (void)setGridVisible:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDGridVisibleKey];
}

- (BOOL)isGridEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDGridEnabledKey];
}
- (void)setGridEnabled:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDGridEnabledKey];
}

- (CGFloat)gridTolerance {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kEDGridToleranceKey];
}
- (void)setGridTolerance:(CGFloat)f {
    [[NSUserDefaults standardUserDefaults] setDouble:f forKey:kEDGridToleranceKey];
}

- (NSArray *)presetMetricsInfos {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDPresetMetricsInfosKey];
}
- (void)setPresetMetricsInfos:(NSArray *)a {
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:kEDPresetMetricsInfosKey];
}

- (EDMetrics *)lastSelectedMetrics {
    NSDictionary *info = [[NSUserDefaults standardUserDefaults] objectForKey:kEDLastSelectedMetricsKey];
    
    EDMetrics *m = nil;
    if ([info count]) {
        m = [EDMetrics metricsFromPlist:info];
    }
    return m;
}

- (NSString *)pythonExePath {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDPythonExePathKey];
}
- (void)setPythonExePath:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:[[s copy] autorelease] forKey:kEDPythonExePathKey];
}

- (NSString *)commandString {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDCommandStringKey];
}
- (void)setCommandString:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:[[s copy] autorelease] forKey:kEDCommandStringKey];
}

- (NSArray *)environmentVariables {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDEnvironmentVariablesKey];
}
- (void)setEnvironmentVariables:(NSArray *)a {
    [[NSUserDefaults standardUserDefaults] setObject:[[a copy] autorelease] forKey:kEDEnvironmentVariablesKey];
}

- (BOOL)exportAlphaEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDExportAlphaEnabledKey];
}

- (void)setExportAlphaEnabled:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDExportAlphaEnabledKey];
}

- (NSInteger)exportType {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kEDExportTypeKey];
}

- (void)setExportType:(NSInteger)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kEDExportTypeKey];
}

- (BOOL)findInProjectMatchCase {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDFindInProjectMatchCaseKey];
}

- (void)setFindInProjectMatchCase:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDFindInProjectMatchCaseKey];
}

- (BOOL)findInProjectUseRegex {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDFindInProjectUseRegexKey];
}

- (void)setFindInProjectUseRegex:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDFindInProjectUseRegexKey];
}

- (BOOL)findInProjectWrapAround {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDFindInProjectWrapAroundKey];
}

- (void)setFindInProjectWrapAround:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDFindInProjectWrapAroundKey];
}

- (NSString *)coreGraphicsHeaderPath {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDCoreGraphicsHeaderPathKey];
}
- (void)setCoreGraphicsHeaderPath:(NSString *)str {
    [[NSUserDefaults standardUserDefaults] setObject:str forKey:kEDCoreGraphicsHeaderPathKey];
}

- (NSString *)imageIOHeaderPath {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDImageIOHeaderPathKey];
}
- (void)setImageIOHeaderPathKey:(NSString *)str {
    [[NSUserDefaults standardUserDefaults] setObject:str forKey:kEDImageIOHeaderPathKey];
}

- (NSString *)excludeFilePatternString {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDExcludeFilePatternStringKey];
}
- (void)setExcludeFilePatternString:(NSString *)str {
    [[NSUserDefaults standardUserDefaults] setObject:str forKey:kEDExcludeFilePatternStringKey];
}

- (NSString *)defaultSourceDirName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDDefaultSourceDirNameKey];
}
- (void)setDefaultSourceDirName:(NSString *)str {
    [[NSUserDefaults standardUserDefaults] setObject:str forKey:kEDDefaultSourceDirNameKey];
}

- (NSString *)defaultFontFamily {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDDefaultFontFamilyKey];
}
- (void)setDefaultFontFamily:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kEDDefaultFontFamilyKey];
}

- (void)setDefaultFontSize:(CGFloat)f {
    [[NSUserDefaults standardUserDefaults] setDouble:f forKey:kEDDefaultFontSizeKey];
}
- (CGFloat)defaultFontSize {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kEDDefaultFontSizeKey];
}

- (NSString *)selectedFontFamily {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDSelectedFontFamilyKey];
}
- (void)setSelectedFontFamily:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kEDSelectedFontFamilyKey];
}

- (void)setSelectedFontSize:(CGFloat)f {
    [[NSUserDefaults standardUserDefaults] setDouble:f forKey:kEDSelectedFontSizeKey];
}
- (CGFloat)selectedFontSize {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kEDSelectedFontSizeKey];
}

- (NSString *)defaultThemeName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDDefaultThemeNameKey];
}
- (void)setDefaultThemeName:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kEDDefaultThemeNameKey];
}

- (NSString *)selectedThemeName {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kEDSelectedThemeNameKey];
}
- (void)setSelectedThemeName:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kEDSelectedThemeNameKey];
}

- (BOOL)suppressConsolePrompt {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kEDSuppressConsolePromptKey];
}
- (void)setSuppressConsolePrompt:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kEDSuppressConsolePromptKey];
}

@end
