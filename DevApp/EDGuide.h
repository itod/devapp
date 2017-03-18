//
//  EDGuide.h
//  Editor
//
//  Created by Todd Ditchendorf on 11/27/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDModel.h"

@class EDCanvasView;

typedef NS_OPTIONS(NSUInteger, EDGuideType) {
    EDGuideTypeCanvasBounds,
    EDGuideTypeObjectBounds,  
    EDGuideTypeUser,  
};

@interface EDGuide : EDModel // <NSCoding>

+ (EDGuide *)guideWithCanvas:(EDCanvasView *)c type:(EDGuideType)t from:(CGPoint)inP1 to:(CGPoint)inP2;

- (id)initWithCanvas:(EDCanvasView *)c type:(EDGuideType)t from:(CGPoint)inP1 to:(CGPoint)inP2;

- (void)moveToP1:(CGPoint)newp1 p2:(CGPoint)newp2;

- (void)drawInContext:(CGContextRef)ctx dirtyRect:(CGRect)drect;
- (BOOL)isVertical;
- (BOOL)isUserGuide;
- (BOOL)isOffscreen;
- (BOOL)containsPoint:(CGPoint)p;
- (BOOL)isSelected;
- (BOOL)isShape;
- (BOOL)isConnectedTo:(id)obj;

- (CGRect)dirtyRect;
- (CGRect)frame;
- (CGFloat)currentScale;

@property (nonatomic, assign) EDGuideType type;
@property (nonatomic, assign) CGPoint p1;
@property (nonatomic, assign) CGPoint p2;
@property (nonatomic, assign) EDCanvasView *canvasView; // weak ref
@end
