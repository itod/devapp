//
//  FNAbstractFunction.h
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "XPFunctionBody.h"

@interface FNAbstractFunction : XPFunctionBody
+ (void)setIdentifier:(NSString *)identifier;

- (void)postUpate;
- (NSColor *)asColor:(XPObject *)obj;

@property (nonatomic, retain, readonly) NSString *identifier;

@property (nonatomic, retain) NSGraphicsContext *canvasGraphicsContext;
@property (nonatomic, retain) NSMutableArray *strokeWeightStack;
@end
