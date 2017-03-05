//
//  EDShellViewController.h
//  Editor
//
//  Created by Todd Ditchendorf on 12/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "TDViewController.h"
#import <OkudaKit/OKViewController.h>

@class OKViewController;
@class OKTextView;
@class EDHistory;

@interface EDShellViewController : TDViewController <NSTextViewDelegate, OKViewControllerDelegate>

- (IBAction)clear:(id)sender;

- (void)appendPrompt;
- (void)clearPrompt;
- (void)removePrompt;
- (BOOL)isAtPrompt:(NSString **)outPrompt;
- (void)append:(NSString *)msg;
- (void)handleUserCommand:(NSString *)cmd;

- (void)selectedThemeDidChange:(NSNotification *)n;

- (NSRange)rangeOfPromptInLine:(NSString *)line;
- (NSArray *)prompts;

@property (nonatomic, retain) OKViewController *sourceViewController;
@property (nonatomic, retain) IBOutlet OKTextView *textView;

@property (nonatomic, retain) EDHistory *history;
@end
