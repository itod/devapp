//
//  EDCanvasView.h
//  Editor
//
//  Created by Todd Ditchendorf on 6/26/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EDToolTip;
@class EDGuide;
@class SZDocument;

@class EDCanvasView;

extern NSString * const EDCompositionRulerOriginDidChangeNotification;

@protocol EDCanvasViewDelegate <NSObject>
- (void)canvas:(EDCanvasView *)canvas didMoveUserGuide:(EDGuide *)g from:(CGPoint)oldPoint to:(CGPoint)newPoint;

- (void)canvas:(EDCanvasView *)canvas mouseEntered:(NSEvent *)evt;
- (void)canvas:(EDCanvasView *)canvas mouseExited:(NSEvent *)evt;
- (void)canvas:(EDCanvasView *)canvas mouseDown:(NSEvent *)evt;
- (void)canvas:(EDCanvasView *)canvas mouseUp:(NSEvent *)evt;
- (void)canvas:(EDCanvasView *)canvas mouseMoved:(NSEvent *)evt;
- (void)canvas:(EDCanvasView *)canvas mouseDragged:(NSEvent *)evt;
@end

@interface EDCanvasView : NSView

+ (CGFloat)margin;

- (CGPoint)convertPointToComposition:(CGPoint)canvasPoint;
- (CGPoint)convertPointFromComposition:(CGPoint)compPoint;
- (CGRect)convertRectToComposition:(CGRect)canvasRect;
- (CGRect)convertRectFromComposition:(CGRect)compRect;

- (EDGuide *)userGuideAtPoint:(CGPoint)p;
- (void)addUserGuide:(EDGuide *)g;
- (void)removeUserGuide:(EDGuide *)g;
- (void)setNeedsDisplayInUserGuidesDirtyRect;

- (NSRulerView *)verticalRulerView;
- (NSRulerView *)horizontalRulerView;

- (void)scrollToCenter;
- (void)scrollRectToCenter:(CGRect)r;

- (void)updateForZoomScale;
- (void)updateRulersOrigin;

- (CGRect)scaledCompositionFrame;
- (CGRect)scaledCompositionBounds;

@property (nonatomic, assign) id <EDCanvasViewDelegate>delegate; // weakref

@property (nonatomic, assign) SZDocument *document; // weakref
@property (nonatomic, retain) NSImage *image;
@property (nonatomic, retain) EDToolTip *toolTipObject;

@property (nonatomic, retain) EDGuide *draggingUserGuide;
@property (nonatomic, assign) CGPoint dragStartPoint;
@end
