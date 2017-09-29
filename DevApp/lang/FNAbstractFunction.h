//
//  FNAbstractFunction.h
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "XPFunctionBody.h"

typedef void(^FNRenderBlock)(CGContextRef ctx);

@interface FNAbstractFunction : XPFunctionBody
+ (NSString *)identifier;
+ (void)setIdentifier:(NSString *)identifier;

- (void)postUpdate;
- (NSColor *)asColor:(XPObject *)obj;

- (void)render:(FNRenderBlock)block;

@property (nonatomic, assign) NSGraphicsContext *canvasGraphicsContext;
@property (nonatomic, assign, readonly) NSMutableArray *strokeWeightStack;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign) BOOL redraw;
@end
