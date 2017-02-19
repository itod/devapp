//
//  EDWebContainerView.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDViewControllerView.h>

@interface EDWebContainerView : TDViewControllerView

@property (nonatomic, retain) IBOutlet NSView *browserView;
@property (nonatomic, retain) IBOutlet NSView *statusBar;
@property (nonatomic, retain) IBOutlet NSView *findPanel;
@property (nonatomic, retain) IBOutlet NSView *comboField;

@property (nonatomic, assign) BOOL findPanelVisible;

- (CGRect)comboFieldRectForBounds:(CGRect)bounds;
- (CGRect)browserViewRectForBounds:(CGRect)bounds;
- (CGRect)statusBarRectForBounds:(CGRect)bounds;
- (CGRect)findPanelRectForBounds:(CGRect)bounds;
@end
