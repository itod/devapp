//
//  EDCanvasViewController.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/26/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDViewController.h>
#import "EDCanvasView.h"

@class TDStatusBarButton;
@class TDStatusBarPopUpView;
@class SZDocument;

@class EDCanvasViewController;

@protocol EDCanvasViewControllerDelegate <NSObject>
//- (EDMetrics *)metricsForCanvasViewController:(EDCanvasViewController *)cvc;

- (void)canvasViewController:(EDCanvasViewController *)cvc mouseEvent:(NSEvent *)evt;
@end

@interface EDCanvasViewController : TDViewController <EDCanvasViewDelegate>
- (void)update;
- (void)clear;

@property (nonatomic, retain) IBOutlet EDCanvasView *canvasView;
@property (nonatomic, retain) IBOutlet NSScrollView *scrollView;

@property (nonatomic, retain) IBOutlet TDStatusBarPopUpView *zoomPopUpView;
@property (nonatomic, retain) IBOutlet TDStatusBarPopUpView *gridPopUpView;
@property (nonatomic, retain) IBOutlet TDStatusBarButton *metricsButton;

@property (nonatomic, assign) SZDocument *document; // weakref
@property (nonatomic, assign) id <EDCanvasViewControllerDelegate>delegate; // weakref
@end
