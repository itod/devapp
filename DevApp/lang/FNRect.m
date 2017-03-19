//
//  FNRect.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNRect.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNRect

+ (NSString *)name {
    return @"rect";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *x = [XPSymbol symbolWithName:@"x"];
    XPSymbol *y = [XPSymbol symbolWithName:@"y"];
    XPSymbol *width = [XPSymbol symbolWithName:@"width"];
    XPSymbol *height = [XPSymbol symbolWithName:@"height"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x, y, width, height, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x, @"x",
                      y, @"y",
                      width, @"width",
                      height, @"height",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *xObj = [space objectForName:@"x"]; TDAssert(xObj);
    XPObject *yObj = [space objectForName:@"y"]; TDAssert(yObj);
    XPObject *widthObj = [space objectForName:@"width"]; TDAssert(widthObj);
    XPObject *heightObj = [space objectForName:@"height"]; TDAssert(heightObj);
    
    double x = [xObj.value doubleValue];
    double y = [yObj.value doubleValue];
    double w = [widthObj.value doubleValue];
    double h = [heightObj.value doubleValue];
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    
    CGRect r = CGRectMake(x, y, w, h);
    
    // FILL
    CGContextFillRect(ctx, r);
    
    // STROKE
    CGContextSaveGState(ctx); {
        CGContextTranslateCTM(ctx, 0.5, 0.5);

        CGContextStrokeRect(ctx, r);
    } CGContextRestoreGState(ctx);
    
    [self postUpate];
    
    return nil;
}

@end
