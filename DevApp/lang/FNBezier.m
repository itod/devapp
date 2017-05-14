//
//  FNBezier.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNBezier.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNBezier

+ (NSString *)name {
    return @"bezier";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *x1 = [XPSymbol symbolWithName:@"x1"];
    XPSymbol *y1 = [XPSymbol symbolWithName:@"y1"];
    XPSymbol *x2 = [XPSymbol symbolWithName:@"x2"];
    XPSymbol *y2 = [XPSymbol symbolWithName:@"y2"];
    XPSymbol *x3 = [XPSymbol symbolWithName:@"x3"];
    XPSymbol *y3 = [XPSymbol symbolWithName:@"y3"];
    XPSymbol *x4 = [XPSymbol symbolWithName:@"x4"];
    XPSymbol *y4 = [XPSymbol symbolWithName:@"y4"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x1, y1, x2, y2, x3, y3, x4, y4, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"y1",
                                   [XPObject nullObject], @"x2",
                                   [XPObject nullObject], @"y2",
                                   [XPObject nullObject], @"x3",
                                   [XPObject nullObject], @"y3",
                                   [XPObject nullObject], @"x4",
                                   [XPObject nullObject], @"y4",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x1, @"x1",
                      y1, @"y1",
                      x2, @"x2",
                      y2, @"y2",
                      x3, @"x3",
                      y3, @"y3",
                      x4, @"x4",
                      y4, @"y4",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *x1Obj = [space objectForName:@"x1"]; TDAssert(x1Obj);
    XPObject *y1Obj = [space objectForName:@"y1"]; TDAssert(y1Obj);
    XPObject *x2Obj = [space objectForName:@"x2"]; TDAssert(x2Obj);
    XPObject *y2Obj = [space objectForName:@"y2"]; TDAssert(y2Obj);
    XPObject *x3Obj = [space objectForName:@"x3"]; TDAssert(x3Obj);
    XPObject *y3Obj = [space objectForName:@"y3"]; TDAssert(y3Obj);
    XPObject *x4Obj = [space objectForName:@"x4"]; TDAssert(x4Obj);
    XPObject *y4Obj = [space objectForName:@"y4"]; TDAssert(y4Obj);
    
    if (4 == argc) {
        if (x1Obj.isArrayObject && 2 == [x1Obj.value count] && y1Obj.isArrayObject && 2 == [y1Obj.value count] &&
            x2Obj.isArrayObject && 2 == [x2Obj.value count] && y2Obj.isArrayObject && 2 == [y2Obj.value count])
        {
            y4Obj = [y2Obj.value objectAtIndex:1];
            x4Obj = [y2Obj.value objectAtIndex:0];
            y3Obj = [x2Obj.value objectAtIndex:1];
            x3Obj = [x2Obj.value objectAtIndex:0];

            y2Obj = [y1Obj.value objectAtIndex:1];
            x2Obj = [y1Obj.value objectAtIndex:0];
            y1Obj = [x1Obj.value objectAtIndex:1];
            x1Obj = [x1Obj.value objectAtIndex:0];
        } else {
            [self raise:XPTypeError format:@"when calling `%@()` with four arguments, argument must be an Array containting four point Array objects: [x1, y1], [x2, y2], [x3, y3], [x4, y4]", [[self class] name]];
        }
    } else  if (1 == argc) {
        if (x1Obj.isArrayObject && 4 == [x1Obj.value count] &&
            [[x1Obj.value objectAtIndex:0] isArrayObject] && 2 == [[[x1Obj.value objectAtIndex:0] value] count] &&
            [[x1Obj.value objectAtIndex:1] isArrayObject] && 2 == [[[x1Obj.value objectAtIndex:1] value] count] &&
            [[x1Obj.value objectAtIndex:2] isArrayObject] && 2 == [[[x1Obj.value objectAtIndex:2] value] count] &&
            [[x1Obj.value objectAtIndex:3] isArrayObject] && 2 == [[[x1Obj.value objectAtIndex:3] value] count])
        {
            y4Obj = [[[x1Obj.value objectAtIndex:3] value] objectAtIndex:1];
            x4Obj = [[[x1Obj.value objectAtIndex:3] value] objectAtIndex:0];
            y3Obj = [[[x1Obj.value objectAtIndex:2] value] objectAtIndex:1];
            x3Obj = [[[x1Obj.value objectAtIndex:2] value] objectAtIndex:0];

            y2Obj = [[[x1Obj.value objectAtIndex:1] value] objectAtIndex:1];
            x2Obj = [[[x1Obj.value objectAtIndex:1] value] objectAtIndex:0];
            y1Obj = [[[x1Obj.value objectAtIndex:0] value] objectAtIndex:1];
            x1Obj = [[[x1Obj.value objectAtIndex:0] value] objectAtIndex:0];
        } else {
            [self raise:XPTypeError format:@"when calling `%@()` with one argument, argument must be an Array containting four point Array objects: [[x1, y1], [x2, y2], [x3, y3], [x4, y4]]", [[self class] name]];
        }
    }
    
    double x1 = x1Obj.doubleValue;
    double y1 = y1Obj.doubleValue;
    double x2 = x2Obj.doubleValue;
    double y2 = y2Obj.doubleValue;
    double x3 = x3Obj.doubleValue;
    double y3 = y3Obj.doubleValue;
    double x4 = x4Obj.doubleValue;
    double y4 = y4Obj.doubleValue;
    
    NSInteger weight = [[self.strokeWeightStack lastObject] integerValue];

    CGMutablePathRef path = CGPathCreateMutable(); {
        BOOL isOdd = (weight & 1);
        if (isOdd) {
            if (x1 == x2) {
                x1 += 0.5;
                x2 += 0.5;
            }
            if (x3 == x4) {
                x3 += 0.5;
                x4 += 0.5;
            }
            if (y1 == y2) {
                y1 += 0.5;
                y2 += 0.5;
            }
            if (y3 == y4) {
                y3 += 0.5;
                y4 += 0.5;
            }
        }
        
        CGPathMoveToPoint(path, NULL, x1, y1);
        CGPathAddCurveToPoint(path, NULL, x2, y2, x3, y3, x4, y4);

        CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
        CGContextAddPath(ctx, path);
        CGContextStrokePath(ctx);
        
    } CGPathRelease(path);
    
    [self postUpdate];
    
    return nil;
}

@end
