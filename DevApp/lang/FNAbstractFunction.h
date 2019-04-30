//
//  FNAbstractFunction.h
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "XPFunctionBody.h"

typedef NS_ENUM(NSUInteger, FNShapeModeFlag) {
    FNShapeModeFlagCorner,
    FNShapeModeFlagCorners,
    FNShapeModeFlagCenter,
    FNShapeModeFlagRadius,
};


extern NSString * const FNCanvasDidDebugUpdateNotification;

typedef void(^FNRenderBlock)(CGContextRef ctx, NSInteger strokeWeight);

@interface FNAbstractFunction : XPFunctionBody
+ (NSString *)identifier;
+ (void)setIdentifier:(NSString *)identifier;

- (NSColor *)asColor:(XPObject *)obj;

- (void)render:(FNRenderBlock)block;

- (void)postCanvasDebugUpdate;

@property (nonatomic, assign) NSGraphicsContext *canvasGraphicsContext;
@property (nonatomic, assign, readonly) NSMutableArray *strokeWeightStack;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign) BOOL redraw;
@property (nonatomic, assign) double frameRate;
@property (nonatomic, assign) FNShapeModeFlag shapeMode;
@end
