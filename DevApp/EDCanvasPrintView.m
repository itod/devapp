//
//  EDCanvasPrintView.m
//  Editor
//
//  Created by Todd Ditchendorf on 5/6/12.
//  Copyright (c) 2012 Celestial Teapot Software. All rights reserved.
//

#import "EDCanvasPrintView.h"
#import "EDCanvasView.h"
#import "EDMetrics.h"
#import "EDCanvasViewController.h"

@implementation EDCanvasPrintView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}


- (void)dealloc {
    self.canvas = nil;
    self.metrics = nil;
    [super dealloc];
}


- (void)prepareWithPrintInfo:(NSPrintInfo *)info {
    EDAssertMainThread();
    EDAssert(_canvas);
    EDAssert(_metrics);
    
    CGSize paperSize = [info paperSize];
    
    CGSize compSize = CGSizeMake(_metrics.width, _metrics.height);
        
    BOOL isCompPortrait = compSize.height > compSize.width;
    CGFloat zoomScale = 1.0;
    
    if (isCompPortrait) {
        BOOL isCompLarger = compSize.height > paperSize.height;
        if (isCompLarger) {
            zoomScale = paperSize.height / compSize.height;
        }
    } else {
        BOOL isCompLarger = compSize.width > paperSize.width;
        if (isCompLarger) {
            zoomScale = paperSize.width / compSize.width;
        }
    }

    compSize.width *= zoomScale;
    compSize.height *= zoomScale;
    
    CGFloat x = paperSize.width / 2.0 - compSize.width / 2.0;
    CGFloat y = paperSize.height / 2.0 - compSize.height / 2.0;
    CGRect compFrame = CGRectMake(x, y, compSize.width, compSize.height);

    self.pageRect = compFrame;
    self.zoomScale = zoomScale;

    CGRect frame = CGRectMake(0.0, 0.0, paperSize.width, paperSize.height);
    [self setFrame:frame];
}


- (void)drawRect:(NSRect)dirtyRect {
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(ctx);

    CGContextSaveGState(ctx);
//    CGContextScaleCTM(ctx, _zoomScale, _zoomScale);
    
    NSAssert([_canvas isFlipped], @"");
    
    NSImage *img = _canvas.image;
    CGSize imgSize = [img size];

    CGRect srcRect = CGRectMake(0.0, 0.0, imgSize.width, imgSize.height);
    CGRect destRect = _pageRect;
    [img drawInRect:destRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    
//    CGContextSetLineWidth(ctx, 4.0);
//    CGContextStrokeRect(ctx, [self bounds]);
//    CGContextStrokeRect(ctx, destRect);

    CGContextRestoreGState(ctx);
    
    CGContextRestoreGState(ctx);
}


#pragma mark -
#pragma mark Printing

- (NSPaperOrientation)printingOrientation {
    CGSize compSize = CGSizeMake(_metrics.width, _metrics.height);
    
    BOOL isCompPortrait = compSize.height > compSize.width;
    return  isCompPortrait ? NSPaperOrientationPortrait : NSPaperOrientationLandscape;
}


- (NSUInteger)numberOfPrintedPages {
    return 1;
}


- (NSPoint)locationOfPrintRect:(NSRect)inRect {
    NSPrintOperation *op = [NSPrintOperation currentOperation];
    NSPrintInfo *info = [op printInfo];
    CGSize paperSize = [info paperSize];

    CGPoint p = CGPointMake(paperSize.width / 2.0 - NSMidX(inRect), paperSize.height / 2.0 - NSMidY(inRect));
    return p;
}


- (BOOL)knowsPageRange:(NSRangePointer)range {
    *range = NSMakeRange(1, 1);
    return YES;
}


- (CGRect)rectForAllPages {
    return [self bounds];
}


- (NSRect)rectForPage:(NSInteger)page {
    NSParameterAssert(page == 1);
    
    return _pageRect;
}

@end
