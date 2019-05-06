//
//  FNContains.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNContains.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"
#import "XPBooleanClass.h"

@implementation FNContains

+ (NSString *)name {
    return @"contains";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPBooleanClass classInstance];
    
    XPSymbol *rect = [XPSymbol symbolWithName:@"rectArray"];
    XPSymbol *point = [XPSymbol symbolWithName:@"pointArray"];
    XPSymbol *mode = [XPSymbol symbolWithName:@"rectMode"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:rect, point, mode, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"rectMode",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      rect, @"rectArray",
                      point, @"pointArray",
                      mode, @"rectMode",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *rectObj = [space objectForName:@"rectArray"];
    TDAssert(rectObj);
    XPObject *pointObj = [space objectForName:@"pointArray"];
    TDAssert(pointObj);
    XPObject *modeObj = [space objectForName:@"rectMode"];
    TDAssert(modeObj);
    
    BOOL res = NO;
    
    // TYPE CHECK ARGS
    {
        if (!rectObj.isArrayObject) {
            [self raise:XPTypeError format:@"first argument to `contains()` must be a RectArray"];
            return nil;
        }
        
        if (4 != [rectObj.value count]) {
            [self raise:XPTypeError format:@"first argument to `contains()` must be a RectArray object: [x, y, width, height]"];
            return nil;
        }
        
        if (!pointObj.isArrayObject) {
            [self raise:XPTypeError format:@"second argument to `contains()` must be a PointArray"];
            return nil;
        }
        
        if (2 != [pointObj.value count]) {
            [self raise:XPTypeError format:@"second argument to `contains()` must be a PointArray object: [x, y]"];
            return nil;
        }
    }
    
    // GET SHAPE MODE
    NSInteger mode = 0;
    {
        if ([XPObject nullObject] == modeObj) {
            mode = self.rectMode;
        } else if (!modeObj.isNumericObject) {
            [self raise:XPTypeError format:@"optional third argument to `contains()` must be a Rect Mode: CORNER, CENTER, RADIUS, CORNERS"];
            return nil;
        } else {
            mode = modeObj.integerValue;
        }
    }
    
    CGRect r = ({
        NSArray *v = rectObj.value;
        double x = [[v objectAtIndex:0] doubleValue];
        double y = [[v objectAtIndex:1] doubleValue];
        double w = [[v objectAtIndex:2] doubleValue];
        double h = [[v objectAtIndex:3] doubleValue];

        [self rectWithX:x y:y width:w height:h mode:mode];
    });
    
    CGPoint p = ({
        NSArray *v = pointObj.value;
        double x = [[v objectAtIndex:0] doubleValue];
        double y = [[v objectAtIndex:1] doubleValue];

        CGPointMake(x, y);
    });
    
    res = CGRectContainsPoint(r, p);
    
    return [XPObject boolean:res];
}

@end
