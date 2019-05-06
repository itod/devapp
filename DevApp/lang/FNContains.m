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
    XPSymbol *mode = [XPSymbol symbolWithName:@"shapeMode"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:rect, point, mode, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"shapeMode",
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
    XPObject *modeObj = [space objectForName:@"shapeMode"];
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
    NSInteger shapeMode = 0;
    {
        if ([XPObject nullObject] == modeObj) {
            shapeMode = self.shapeMode;
        } else if (!modeObj.isNumericObject) {
            [self raise:XPTypeError format:@"optional third argument to `contains()` must be a Shape Mode: CORNER, CENTER, RADIUS, CORNERS"];
            return nil;
        } else {
            shapeMode = modeObj.integerValue;
        }
    }
    
    CGRect r = ({
        NSArray *v = rectObj.value;
        double x = [[v objectAtIndex:0] doubleValue];
        double y = [[v objectAtIndex:1] doubleValue];
        double w = [[v objectAtIndex:2] doubleValue];
        double h = [[v objectAtIndex:3] doubleValue];

        [self rectWithX:x y:y width:w height:h mode:shapeMode];
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
