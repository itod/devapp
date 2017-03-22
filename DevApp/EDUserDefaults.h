//
//  EDUserDefaults.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDEUserDefaults.h"

@class EDMetrics;

// User Defaults Keys
#define kEDShowWelcomeWindowOnLaunchKey @"EDShowWelcomeWindowOnLaunch"

#define kEDDocumentationHomeURLStringKey @"EDDocumentationHomeURLString"

#define kEDTabsListViewVisibleKey @"EDTabsListViewVisible"
#define kEDStatusBarVisibleKey @"EDStatusBarVisible"
#define kEDNavigatorViewVisibleKey @"EDNavigatorViewVisible"
#define kEDCanvasViewVisibleKey @"EDCanvasViewVisible"
#define kEDConsoleViewVisibleKey @"EDConsoleViewVisible"
#define kEDDebugLocalVariablesVisibleKey @"EDDebugLocalVariablesVisible"

#define kEDBreakpointsEnabledKey @"EDBreakpointsEnabled"

#define kEDRulersVisibleKey @"EDRulersVisible"
#define kEDGridVisibleKey @"EDGridVisible"
#define kEDGuidesVisibleKey @"EDGuidesVisible"
#define kEDGuidesLockedKey @"EDGuidesLocked"

#define kEDFlippedKey @"EDFlipped"
#define kEDGridEnabledKey @"EDGridEnabled"
#define kEDGridToleranceKey @"EDGridTolerance"

#define kEDPresetMetricsInfosKey @"EDPresetMetricsInfos"
#define kEDLastSelectedMetricsKey @"EDLastSelectedMetrics"

#define kEDPythonExePathKey @"EDPythonExePath"
#define kEDCommandStringKey @"EDCommandString"
#define kEDEnvironmentVariablesKey @"EDEnvironmentVariables"

#define kEDExportAlphaEnabledKey @"EDExportAlphaEnabled"
#define kEDExportTypeKey @"EDExportType"

#define kEDCoreGraphicsHeaderPathKey @"EDCoreGraphicsHeaderPath"
#define kEDImageIOHeaderPathKey @"EDImageIOHeaderPath"

#define kEDFindInProjectMatchCaseKey @"EDFindInProjectMatchCase"
#define kEDFindInProjectUseRegexKey @"EDFindInProjectUseRegex"
#define kEDFindInProjectWrapAroundKey @"EDFindInProjectWrapAround"

#define kEDExcludeFilePatternStringKey @"EDExcludeFilePatternString"

#define kEDDefaultFontFamilyKey @"OKDefaultFontFamily"
#define kEDDefaultFontSizeKey @"OKDefaultFontSize"
#define kEDSelectedFontFamilyKey @"OKSelectedFontFamily"
#define kEDSelectedFontSizeKey @"OKSelectedFontSize"

#define kEDDefaultThemeNameKey @"EDDefaultThemeName"
#define kEDSelectedThemeNameKey @"EDSelectedThemeName"

#define kEDSuppressConsolePromptKey @"EDSuppressConsolePrompt"

// Notification Names
extern NSString * const EDTabsListViewVisibleDidChangeNotification;
extern NSString * const EDStatusBarVisibleDidChangeNotification;

extern NSString * const EDNavigatorViewVisibleDidChangeNotification;
extern NSString * const EDCanvasViewVisibleDidChangeNotification;
extern NSString * const EDConsoleViewVisibleDidChangeNotification;
extern NSString * const EDDebugLocalVariablesVisibleDidChangeNotification;

extern NSString * const EDBreakpointsEnabledDidChangeNotification;
extern NSString * const EDBreakpointsDidChangeNotification;

extern NSString * const EDSelectedThemeDidChangeNotification;

extern NSString * const EDRulersVisibleDidChangeNotification;
extern NSString * const EDGridVisibleDidChangeNotification;
extern NSString * const EDGuidesVisibleDidChangeNotification;
extern NSString * const EDGuidesLockedDidChangeNotification;

extern NSString * const EDCompositionMetricsDidChangeNotification;
extern NSString * const EDCompositionZoomScaleDidChangeNotification;
extern NSString * const EDCompositionGridEnabledDidChangeNotification;
extern NSString * const EDCompositionGridToleranceDidChangeNotification;

// Notification Observer methods
@interface NSObject (EDNotificationObserver)
- (void)tabsListViewVisibleDidChange:(NSNotification *)n;
- (void)statusBarVisibleDidChange:(NSNotification *)n;
- (void)navigatorViewVisibleDidChange:(NSNotification *)n;
- (void)canvasViewVisibleDidChange:(NSNotification *)n;
- (void)consoleViewVisibleDidChange:(NSNotification *)n;
- (void)debugLocalVariablesVisibleDidChange:(NSNotification *)n;

- (void)breakpointsEnabledDidChange:(NSNotification *)n;
- (void)breakpointsDidChange:(NSNotification *)n;

- (void)pythonWillStartup:(NSNotification *)n;
- (void)pythonDidStartup:(NSNotification *)n;
@end

@interface EDUserDefaults : IDEUserDefaults

+ (instancetype)instance;

@property (nonatomic, assign) BOOL showWelcomeWindowOnLaunch;

@property (nonatomic, copy) NSString *documentationHomeURLString;

@property (nonatomic, assign) BOOL tabsListViewVisible;
@property (nonatomic, assign) BOOL statusBarVisible;
@property (nonatomic, assign) BOOL navigatorViewVisible;
@property (nonatomic, assign) BOOL canvasViewVisible;
@property (nonatomic, assign) BOOL consoleViewVisible;
@property (nonatomic, assign) BOOL debugLocalVariablesVisible;

@property (nonatomic, assign) BOOL breakpointsEnabled;

@property (nonatomic, assign) BOOL rulersVisible;
@property (nonatomic, assign) BOOL gridVisible;
@property (nonatomic, assign) BOOL guidesVisible;
@property (nonatomic, assign) BOOL guidesLocked;

@property (nonatomic, assign, getter=isGridEnabled) BOOL gridEnabled;
@property (nonatomic, assign) CGFloat gridTolerance;

@property (nonatomic, copy) NSArray *presetMetricsInfos;
@property (nonatomic, retain, readonly) EDMetrics *lastSelectedMetrics;

@property (nonatomic, copy) NSString *pythonExePath;
@property (nonatomic, copy) NSString *commandString;
@property (nonatomic, copy) NSArray *environmentVariables;

@property (nonatomic, assign) BOOL exportAlphaEnabled;
@property (nonatomic, assign) NSInteger exportType;

@property (nonatomic, assign) BOOL findInProjectMatchCase;
@property (nonatomic, assign) BOOL findInProjectUseRegex;
@property (nonatomic, assign) BOOL findInProjectWrapAround;

@property (nonatomic, copy) NSString *excludeFilePatternString;
@property (nonatomic, copy, readonly) NSArray *excludeFilePatterns;

@property (nonatomic, copy) NSString *defaultFontFamily;
@property (nonatomic, assign) CGFloat defaultFontSize;
@property (nonatomic, copy) NSString *selectedFontFamily;
@property (nonatomic, assign) CGFloat selectedFontSize;

@property (nonatomic, copy) NSString *defaultThemeName;
@property (nonatomic, copy) NSString *selectedThemeName;

@property (nonatomic, assign) BOOL suppressConsolePrompt;
@end
