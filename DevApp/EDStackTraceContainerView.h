//
//  EDStackTraceContainerView.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDViewControllerView.h>

@interface EDStackTraceContainerView : TDViewControllerView

@property (nonatomic, retain) IBOutlet NSScrollView *scrollView;
@property (nonatomic, retain) IBOutlet NSView *statusBar;

- (CGRect)scrollViewRectForBounds:(CGRect)bounds;
- (CGRect)statusBarRectForBounds:(CGRect)bounds;
@end
