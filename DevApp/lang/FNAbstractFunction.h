//
//  FNAbstractFunction.h
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "XPFunctionBody.h"

@interface FNAbstractFunction : XPFunctionBody
+ (NSString *)identifier;
+ (void)setIdentifier:(NSString *)identifier;

- (void)postUpate;
- (NSColor *)asColor:(XPObject *)obj;

@property (nonatomic, assign) NSGraphicsContext *canvasGraphicsContext;
@property (nonatomic, assign, readonly) NSMutableArray *strokeWeightStack;
@end
