//
//  EXDocumentController.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TabKit/TKDocumentController.h>

#ifndef APPSTORE
@class TDRegisterWindowController;
@class EDWelcomeWindowController;
#endif

@interface EDDocumentController : TKDocumentController

// tabs / status bar
- (IBAction)toggleTabsListViewVisible:(id)sender;
- (IBAction)toggleStatusBarVisible:(id)sender;

// palettes
- (IBAction)toggleNavigatorVisible:(id)sender;
- (IBAction)toggleCanvasViewVisible:(id)sender;
- (IBAction)toggleConsoleViewVisible:(id)sender;
- (IBAction)toggleDebugLocalVaraiblesVisible:(id)sender;

// license
#ifndef APPSTORE
- (IBAction)showWelcomeWindow:(id)sender;

- (IBAction)purchase:(id)sender;
- (IBAction)registerApp:(id)sender;
- (IBAction)showLicenseInfo:(id)sender;

- (BOOL)isLicensed;
- (BOOL)registerWithLicenseAtPath:(NSString *)path;
- (NSString *)licenseExtension;
- (NSDictionary *)licenseDictionary;
- (BOOL)installLicenseAtPath:(NSString *)srcPath;
- (void)runInvalidLicenseDialog;
- (void)runThankYouDialog;
- (void)runNagDialog;
- (NSString *)nagText;
- (NSString *)licensePath;
- (NSString *)publicKey;

@property (nonatomic, retain) TDRegisterWindowController *registerWindowController;
@property (nonatomic, retain) EDWelcomeWindowController *welcomeWindowController;
#endif
@end
