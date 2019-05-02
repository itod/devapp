//
//  FNPopStyle.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNPopStyle.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNPopStyle

+ (NSString *)name {
    return @"popStyle";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextRestoreGState(ctx);
    
    [self.strokeWeightStack removeLastObject];
    [self.noStrokeStack removeLastObject];

    return nil;
}

@end
