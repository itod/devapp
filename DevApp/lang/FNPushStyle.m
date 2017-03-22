//
//  FNPushStyle.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNPushStyle.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNPushStyle

+ (NSString *)name {
    return @"pushStyle";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker argc:(NSUInteger)argc {
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextSaveGState(ctx);
    
    [self.strokeWeightStack addObject:[self.strokeWeightStack lastObject]];
    
    return nil;
}

@end
