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
#import "XPNullClass.h"

@implementation FNStroke

+ (NSString *)name {
    return @"stroke";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPNullClass classInstance];
    
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
    
    switch (argc) {
        case 1: {
            NSColor *c = [self asColor:rObj];
            CGContextSetRGBStrokeColor(ctx, [c redComponent], [c greenComponent], [c blueComponent], [c alphaComponent]);
        } break;
        case 2: {
            XPObject *gObj = [space objectForName:@"g"]; TDAssert(gObj);
            double white = rObj.doubleValue;
            double alhpa = gObj.doubleValue;
            CGContextSetGrayStrokeColor(ctx, white, alhpa);
        } break;
        case 3:
        case 4:
        {
            XPObject *gObj = [space objectForName:@"g"]; TDAssert(gObj);
            XPObject *bObj = [space objectForName:@"b"]; TDAssert(bObj);
            XPObject *aObj = [space objectForName:@"a"]; TDAssert(aObj);
            
            double r = rObj.doubleValue/255.0;
            double g = gObj.doubleValue/255.0;
            double b = bObj.doubleValue/255.0;
            double a = aObj.doubleValue;
            CGContextSetRGBStrokeColor(ctx, r, g, b, a);
        } break;
        default:
            TDAssert(0);
            break;
    }
    
    return nil;
}

@end
