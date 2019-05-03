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
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"
#import "XPNullClass.h"

@implementation FNRect

+ (NSString *)name {
    return @"rect";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPNullClass classInstance];
    
    XPSymbol *x = [XPSymbol symbolWithName:@"x"];
    XPSymbol *y = [XPSymbol symbolWithName:@"y"];
    XPSymbol *width = [XPSymbol symbolWithName:@"width"];
    XPSymbol *height = [XPSymbol symbolWithName:@"height"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x, y, width, height, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"y",
                                   [XPObject nullObject], @"width",
                                   [XPObject nullObject], @"height",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x, @"x",
                      y, @"y",
                      width, @"width",
                      height, @"height",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *xObj = [space objectForName:@"x"]; TDAssert(xObj);
    XPObject *yObj = [space objectForName:@"y"]; TDAssert(yObj);
    XPObject *wObj = [space objectForName:@"width"]; TDAssert(wObj);
    XPObject *hObj = [space objectForName:@"height"]; TDAssert(hObj);
    
    if (1 == argc) {
        if (xObj.isArrayObject && 4 == [xObj.value count]) {
            NSArray *v = xObj.value;
            xObj = [v objectAtIndex:0];
            yObj = [v objectAtIndex:1];
            wObj = [v objectAtIndex:2];
            hObj = [v objectAtIndex:3];
        } else {
            [self raise:XPTypeError format:@"when calling `%@()` with one argument, argument must be a rectangle Array object: [x, y, width, height]", [[self class] name]];
        }
    }
    
    double x = xObj.doubleValue;
    double y = yObj.doubleValue;
    double w = wObj.doubleValue;
    double h = hObj.doubleValue;
    
    FNShapeModeFlag mode = self.shapeMode;
    CGRect r = [self rectWithX:x y:y width:w height:h mode:mode];
    
    [self render:^(CGContextRef ctx, NSInteger strokeWeight) {
        // FILL
        {
            //CGRect fillRect = CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height);
            CGContextFillRect(ctx, r);
        }
        
        // STROKE
        {
            if (strokeWeight > 0) {
                //CGRect strokeRect = CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height);
                CGContextStrokeRect(ctx, r);
            }
        }
    }];
    
    return nil;
}

@end
