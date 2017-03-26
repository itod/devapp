//
//  FNLine.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNLine.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

#define TDIsAngleBetween(angle, low, high) ((angle) >= (low) && (angle) <= (high))
#define TDGetAngleBetween(p1, p2) (TDR2D(atan2((p2).y - (p1).y, (p2).x - (p1).x)) + 180.0)

@implementation FNLine

+ (NSString *)name {
    return @"line";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *x1 = [XPSymbol symbolWithName:@"x1"];
    XPSymbol *y1 = [XPSymbol symbolWithName:@"y1"];
    XPSymbol *x2 = [XPSymbol symbolWithName:@"x2"];
    XPSymbol *y2 = [XPSymbol symbolWithName:@"y2"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x1, y1, x2, y2, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"y1",
                                   [XPObject nullObject], @"x2",
                                   [XPObject nullObject], @"y2",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x1, @"x1",
                      y1, @"y1",
                      x2, @"x2",
                      y2, @"y2",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker argc:(NSUInteger)argc {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *x1Obj = [space objectForName:@"x1"]; TDAssert(x1Obj);
    XPObject *y1Obj = [space objectForName:@"y1"]; TDAssert(y1Obj);
    XPObject *x2Obj = [space objectForName:@"x2"]; TDAssert(x2Obj);
    XPObject *y2Obj = [space objectForName:@"y2"]; TDAssert(y2Obj);
    
    if (2 == argc) {
        if (x1Obj.isArrayObject && 2 == [x1Obj.value count] && y1Obj.isArrayObject && 2 == [y1Obj.value count]) {
            x1Obj = [x1Obj.value objectAtIndex:0];
            y1Obj = [x1Obj.value objectAtIndex:1];
            x2Obj = [y1Obj.value objectAtIndex:0];
            y2Obj = [y1Obj.value objectAtIndex:1];
        } else {
            [self raise:XPTypeError format:@"when calling `%@()` with one argument, argument must be an Array containting two point Array objects: [[x, y], [x, y]]", [[self class] name]];
        }
    }
    
    double x1 = x1Obj.doubleValue;
    double y1 = y1Obj.doubleValue;
    double x2 = x2Obj.doubleValue;
    double y2 = y2Obj.doubleValue;
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    
    NSInteger weight = [[self.strokeWeightStack lastObject] integerValue];

    BOOL isOdd = (weight & 1);
    if (isOdd) {
        if (x1 == x2) {
            x1 += 0.5;
            x2 += 0.5;
        }
        if (y1 == y2) {
            y1 += 0.5;
            y2 += 0.5;
        }
        CGContextMoveToPoint(ctx, x1, y1);
        CGContextAddLineToPoint(ctx, x2, y2);
    } else {
        CGContextMoveToPoint(ctx, x1, y1);
        CGContextAddLineToPoint(ctx, x2, y2);
    }
    CGContextStrokePath(ctx);
    
    [self postUpate];
    
    return nil;
}

@end
