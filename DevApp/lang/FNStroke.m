//
//  FNStroke.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNStroke.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNStroke

+ (NSString *)name {
    return @"stroke";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *r = [XPSymbol symbolWithName:@"r"];
    XPSymbol *b = [XPSymbol symbolWithName:@"b"];
    XPSymbol *g = [XPSymbol symbolWithName:@"g"];
    XPSymbol *a = [XPSymbol symbolWithName:@"a"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:r, g, b, a, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject number:0.0], @"g",
                                   [XPObject number:0.0], @"b",
                                   [XPObject number:1.0], @"a",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      r, @"r",
                      g, @"g",
                      b, @"b",
                      a, @"a",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {    
    XPObject *rObj = [space objectForName:@"r"]; TDAssert(rObj);
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    if (1 == argc) {
        NSColor *c = [self asColor:rObj];
        CGContextSetRGBStrokeColor(ctx, [c redComponent], [c greenComponent], [c blueComponent], [c alphaComponent]);
    } else {
        XPObject *gObj = [space objectForName:@"g"]; TDAssert(gObj);
        XPObject *bObj = [space objectForName:@"b"]; TDAssert(bObj);
        XPObject *aObj = [space objectForName:@"a"]; TDAssert(aObj);
        
        double r = rObj.doubleValue;
        double g = gObj.doubleValue;
        double b = bObj.doubleValue;
        double a = aObj.doubleValue;
        CGContextSetRGBStrokeColor(ctx, r, g, b, a);
    }
    
    return nil;
}

@end
