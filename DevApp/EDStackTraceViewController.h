//
//  EDStackTraceViewController.h
//  Editor
//
//  Created by Todd Ditchendorf on 12/17/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "TDViewController.h"

@class EDStackTraceViewController;
@class EDFileLocation;

@protocol EDStackTraceViewControllerDelegate <NSObject>
- (void)stackTraceViewController:(EDStackTraceViewController *)stvc didActivateFileLocation:(EDFileLocation *)fileLoc stackFrameIndex:(NSUInteger)idx;
- (NSString *)sourceDirPathForStackTraceViewController:(EDStackTraceViewController *)stvc;
@end

@interface EDStackTraceViewController : TDViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, assign) id<EDStackTraceViewControllerDelegate> delegate; // weakref

@property (nonatomic, retain) IBOutlet NSOutlineView *outlineView;

- (void)displayDebugInfo:(NSArray *)info;
- (void)clearDebugInfo;
@end
