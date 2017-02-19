//
//  EXContainerView.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/12/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDFlippedView.h>

@interface EDWindowContainerView : TDFlippedView

@property (nonatomic, assign) CGFloat tabsListViewHeight;

@property (nonatomic, retain) IBOutlet NSView *tabsListView;
@property (nonatomic, retain) IBOutlet NSView *uberView;

- (CGRect)tabsListViewRectForBounds:(CGRect)bounds;
- (CGRect)uberViewRectForBounds:(CGRect)bounds;
@end
