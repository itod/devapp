//
//  EDWindowController.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/13/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TabKit/TKMainWindowController.h>
#import <OkudaKit/OKViewController.h>
#import <OkudaKit/OKTextView.h>
#import <OkudaKit/OKGutterView.h>
#import <TDAppKit/TDTabBarController.h>
#import "EDCodeRunner.h"
#import "EDFilesystemViewController.h"
#import "EDStackTraceViewController.h"
#import "EDBreakpointListViewController.h"
#import "EDConsoleViewController.h"
#import "EDFindViewController.h"
#import "EDFileEncodingDialogController.h"

@class EDWindowContainerView;
@class EDMidContainerView;
@class EDToolbarButtonItem;
@class IDEUberView;
@class EDCanvasViewController;
@class EDConsoleViewController;
@class EDFindViewController;
@class EDProjectWindowController;
@class EDFileWindowController;
@class EDFileLocation;
@class EDFileEncodingDialogController;

@class OKSource;

@interface EDMainWindowController : TKMainWindowController <TDTabBarControllerDelegate, EDCodeRunnerDelegate, EDFilesystemViewControllerDelegate, EDStackTraceViewControllerDelegate, EDBreakpointListViewControllerDelegate, EDConsoleViewControllerDelegate, EDFindViewControllerDelegate, EDFileEncodingDialogControllerDelegate, OKTextViewListDataSource, OKTextViewListDelegate, OKGutterViewDelegate>

+ (NSArray *)triggers;

- (id)init; // use me

@property (nonatomic, assign) BOOL canGoBack;
@property (nonatomic, assign) BOOL canGoForward;
- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;

- (IBAction)findInFile:(id)sender;
- (IBAction)findInProject:(id)sender;
- (IBAction)findAndReplaceInFile:(id)sender;
- (IBAction)findAndReplaceInProject:(id)sender;

- (IBAction)myFindPanelAction:(id)sender;
- (IBAction)performFindPanelAction:(id)sender;

- (IBAction)showReference:(id)sender;

// navigators
- (IBAction)showFilesystemNavigator:(id)sender;
- (IBAction)showStackTraceNavigator:(id)sender;
- (IBAction)showBreakpointListNavigator:(id)sender;

- (IBAction)run:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)clear:(id)sender;

@property (nonatomic, assign) BOOL canRun;
@property (nonatomic, assign) BOOL canStop;
@property (nonatomic, assign) BOOL busy;
@property (nonatomic, assign) BOOL paused;

- (IBAction)editProjectSettings:(id)sender;

- (IBAction)newREPLTab:(id)sender;
- (IBAction)newFile:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)cont:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)step:(id)sender;
- (IBAction)finish:(id)sender;
- (IBAction)activateConsole:(id)sender;
- (IBAction)hideFindView:(id)sender;

- (IBAction)toggleBreakpointsEnabled:(id)sender;

@property (nonatomic, retain) id <EDCodeRunner>codeRunner;

@property (nonatomic, retain) IBOutlet EDWindowContainerView *windowContainerView;
@property (nonatomic, retain) IBOutlet EDMidContainerView *midContainerView;
@property (nonatomic, retain) IBOutlet EDToolbarButtonItem *breakpointsEnabledToolbarItem;
@property (nonatomic, retain) IDEUberView *outerUberView;
@property (nonatomic, retain) IDEUberView *innerUberView;
@property (nonatomic, retain) TDTabBarController *navigatorTabBarController;
@property (nonatomic, retain) EDFilesystemViewController *filesystemViewController;
@property (nonatomic, retain) EDStackTraceViewController *stackTraceViewController;
@property (nonatomic, retain) EDBreakpointListViewController *breakpointListViewController;
@property (nonatomic, retain) EDCanvasViewController *canvasViewController;
@property (nonatomic, retain) EDConsoleViewController *consoleViewController;
@property (nonatomic, retain) EDFindViewController *findViewController;
@property (nonatomic, retain) EDFileWindowController *fileWindowController;
@property (nonatomic, retain) EDFileEncodingDialogController *fileEncodingDialogController;
@property (nonatomic, retain) EDProjectWindowController *projectWindowController;

@property (nonatomic, retain) NSString *statusText;
@property (nonatomic, assign, getter=isTypingInFindPanel) BOOL typingInFindPanel;
@property (nonatomic, assign, readonly) BOOL multiFileEnabled;

@property (nonatomic, copy, readonly) NSString *sourceDirPath;
@property (nonatomic, copy, readonly) NSString *mainSourceFilePath;

- (NSString *)absolutePathForTabModel:(TKTabModel *)tm;
- (NSString *)absoluteSourceFilePathForRelativeSourceFilePath:(NSString *)relPath;
- (NSString *)relativeSourceFilePathForAbsoluteSourceFilePath:(NSString *)absPath;

- (OKSource *)loadSourceForFileAtPath:(NSString *)absPath error:(NSError **)outErr;
- (OKSource *)loadSourceFromDiskForFileAtPath:(NSString *)absPath error:(NSError **)outErr;
- (void)storeInMemorySource:(OKSource *)source forFileAtPath:(NSString *)absPath;

- (void)saveSelectedTabModel;
- (void)saveAllDirtyFiles;

// subclass
- (void)showConsoleView;
- (NSArray *)allEnabledBreakpointsPlist;
- (void)navigateToFileLocationInCurrentTab:(EDFileLocation *)fileLoc;

@property (nonatomic, retain, readonly) OKViewController *selectedSourceViewController;
@end
