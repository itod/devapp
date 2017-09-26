//
//  EDConsoleViewController.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDShellViewController.h"

@class EDConsoleViewController;
@class EDConsoleOutlineView;
@class IDEUberView;
@class XPStackFrame;

@protocol EDConsoleViewControllerDelegate <NSObject>
- (void)console:(EDConsoleViewController *)cvc userIssuedCommand:(NSString *)cmd;
- (NSString *)promptForConsole:(EDConsoleViewController *)cvc;
- (BOOL)isConsolePaused:(EDConsoleViewController *)cvc;
- (NSMutableAttributedString *)console:(EDConsoleViewController *)cvc highlightedStringForString:(NSString *)str;
@end

@interface EDConsoleViewController : EDShellViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, assign) id <EDConsoleViewControllerDelegate>delegate; // weakref
@property (nonatomic, retain) IBOutlet NSButton *continueButton;
@property (nonatomic, retain) IBOutlet NSButton *nextButton;
@property (nonatomic, retain) IBOutlet NSButton *stepButton;
@property (nonatomic, retain) IBOutlet NSButton *upButton;

@property (nonatomic, retain) IBOutlet NSView *varsContainerView;
@property (nonatomic, retain) IBOutlet EDConsoleOutlineView *varsOutlineView;
@property (nonatomic, retain) IBOutlet NSMenu *contextMenu;

@property (nonatomic, retain) IDEUberView *uberView;

@property (nonatomic, assign) BOOL canStop;
@property (nonatomic, assign) BOOL paused;

- (IBAction)menuPrintValue:(id)sender;

- (void)displayStackFrame:(XPStackFrame *)frame;
- (void)clearDebugInfo;
@end
