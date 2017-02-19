//
//  EDWelcomeWindowController.h
//  Editor
//
//  Created by Todd Ditchendorf on 9/27/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EDWelcomeWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

- (id)init; // use me

- (IBAction)newProject:(id)sender;
- (IBAction)openSampleProject:(id)sender;

@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, retain) NSString *titleText;
@property (nonatomic, retain) NSString *versionText;
@property (nonatomic, assign) BOOL busy;
@property (nonatomic, assign) BOOL wantsExampleProjButton;
@end
