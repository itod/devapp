//
//  FNFill.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNFill.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNFill

+ (NSString *)name {
    return @"fill";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *color = [XPSymbol symbolWithName:@"color"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:color, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      color, @"color",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *colorObj = [space objectForName:@"color"]; TDAssert(colorObj);
    
    NSColor *c = [self asColor:colorObj];
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextSetRGBFillColor(ctx, [c redComponent], [c greenComponent], [c blueComponent], [c alphaComponent]);
    
    return nil;
}

@end
