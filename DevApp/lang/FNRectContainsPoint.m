//
//  FNRectContainsPoint.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNRectContainsPoint.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNRectContainsPoint

+ (NSString *)name {
    return @"rectContainsPoint";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *rect = [XPSymbol symbolWithName:@"rectArray"];
    XPSymbol *point = [XPSymbol symbolWithName:@"pointArray"];
    XPSymbol *mode = [XPSymbol symbolWithName:@"shapeMode"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:rect, point, mode, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject number:FNShapeModeFlagCorner], @"shapeMode",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      rect, @"rectArray",
                      point, @"pointArray",
                      mode, @"shapeMode",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *rectObj = [space objectForName:@"rectArray"];
    TDAssert(rectObj);
    XPObject *pointObj = [space objectForName:@"pointArray"];
    TDAssert(pointObj);
    XPObject *mode = [space objectForName:@"shapeMode"];
    TDAssert(mode);
    
    BOOL res = NO;
    
    if (rectObj.isArrayObject) {
        if (4 != [rectObj.value count]) {
            [self raise:XPTypeError format:@"rectArray argument to `rectDontainsPoint()` must be a rectangle Array object: [x, y, width, height]"];
            return nil;
        }
        
        if (2 != [pointObj.value count]) {
            [self raise:XPTypeError format:@"pointArray argument to `rectDontainsPoint()` must be a point Array object: [x, y]"];
            return nil;
        }
    
        CGRect r = ({
            NSArray *v = rectObj.value;
            XPObject *xObj = [v objectAtIndex:0];
            XPObject *yObj = [v objectAtIndex:1];
            XPObject *wObj = [v objectAtIndex:2];
            XPObject *hObj = [v objectAtIndex:3];
            
            double x = xObj.doubleValue;
            double y = yObj.doubleValue;
            double w = wObj.doubleValue;
            double h = hObj.doubleValue;
            
            NSInteger shapeMode = lround(mode.doubleValue);
            
            [self rectWithX:x y:y width:w height:h mode:shapeMode];
        });
        
        CGPoint p = ({
            NSArray *v = pointObj.value;
            XPObject *xObj = [v objectAtIndex:0];
            XPObject *yObj = [v objectAtIndex:1];
            
            double x = xObj.doubleValue;
            double y = yObj.doubleValue;
            
            CGPointMake(x, y);
        });
        
        res = CGRectContainsPoint(r, p);

    } else {
        [self raise:XPTypeError format:@"first argument to `rectDontainsPoint()` must be a RectArray object"];
    }
    
    return [XPObject boolean:res];
}

@end
