//
//  EDMidContainerView.h
//  Editor
//
//  Created by Todd Ditchendorf on 8/25/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDViewControllerView.h>

@interface EDMidContainerView : TDViewControllerView

@property (nonatomic, retain) IBOutlet NSView *controlBar;
@property (nonatomic, retain) IBOutlet NSView *uberView;
@property (nonatomic, retain) IBOutlet NSView *statusBar;

- (CGRect)controlBarRectForBounds:(CGRect)bounds;
- (CGRect)uberViewRectForBounds:(CGRect)bounds;
- (CGRect)statusBarRectForBounds:(CGRect)bounds;
@end
