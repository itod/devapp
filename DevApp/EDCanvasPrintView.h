//
//  EDCanvasPrintView.h
//  Editor
//
//  Created by Todd Ditchendorf on 5/6/12.
//  Copyright (c) 2012 Celestial Teapot Software. All rights reserved.
//

#import <TDAppKit/TDFlippedView.h>

@class EDCanvasView;

@interface EDCanvasPrintView : TDFlippedView

- (void)prepareWithPrintInfo:(NSPrintInfo *)info;
- (NSPaperOrientation)printingOrientation;

@property (nonatomic, retain) EDCanvasView *canvas;
@property (nonatomic, retain) EDMetrics *metrics;
@property (nonatomic, assign) CGRect pageRect;
@property (nonatomic, assign) CGFloat zoomScale;
@end
