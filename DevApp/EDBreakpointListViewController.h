//
//  EDBreakpointListViewController.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDViewController.h>

@class EDBreakpointListViewController;
@class EDBreakpointCollection;

@class EDBreakpointCollection;

@protocol EDBreakpointListViewControllerDelegate <NSObject>
- (void)breakpointListViewController:(EDBreakpointListViewController *)bplc didActivateFileAtPath:(NSString *)path lineNumber:(NSUInteger)lineNum;
@end

@interface EDBreakpointListViewController : TDViewController <NSOutlineViewDataSource, NSOutlineViewDelegate, NSMenuDelegate>

- (instancetype)init; // use me

- (void)reloadData;

- (IBAction)menuToggleEnabled:(id)sender;
- (IBAction)menuDelete:(id)sender;

- (void)displayContextMenu:(NSEvent *)evt;

@property (nonatomic, assign) id <EDBreakpointListViewControllerDelegate>delegate; // weakref

@property (nonatomic, retain) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, retain) IBOutlet NSMenu *contextMenu;

@property (nonatomic, retain) IBOutlet EDBreakpointCollection *collection;

@property (nonatomic, assign) BOOL hasSelection;
@end
