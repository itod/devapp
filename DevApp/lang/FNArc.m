//
//  FNArc.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNArc.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"
#import "XPNullClass.h"

@implementation FNArc

+ (NSString *)name {
    return @"arc";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPNullClass classInstance];
    
    XPSymbol *x = [XPSymbol symbolWithName:@"x"];
    XPSymbol *y = [XPSymbol symbolWithName:@"y"];
    XPSymbol *radius = [XPSymbol symbolWithName:@"radius"];
    XPSymbol *startAngle = [XPSymbol symbolWithName:@"startAngle"];
    XPSymbol *endAngle = [XPSymbol symbolWithName:@"endAngle"];
    XPSymbol *clockwise = [XPSymbol symbolWithName:@"clockwise"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x, y, radius, startAngle, endAngle, clockwise, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x, @"x",
                      y, @"y",
                      radius, @"radius",
                      startAngle, @"startAngle",
                      endAngle, @"endAngle",
                      clockwise, @"clockwise",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *xObj = [space objectForName:@"x"]; TDAssert(xObj);
    XPObject *yObj = [space objectForName:@"y"]; TDAssert(yObj);
    XPObject *radiusObj = [space objectForName:@"radius"]; TDAssert(radiusObj);
    XPObject *startAngleObj = [space objectForName:@"startAngle"]; TDAssert(startAngleObj);
    XPObject *endAngleObj = [space objectForName:@"endAngle"]; TDAssert(endAngleObj);
    XPObject *clockwiseObj = [space objectForName:@"clockwise"]; TDAssert(clockwiseObj);
    
    double x = xObj.doubleValue;
    double y = yObj.doubleValue;
    double radius = radiusObj.doubleValue;
    double startAngle = startAngleObj.doubleValue;
    double endAngle = endAngleObj.doubleValue;
    BOOL clockwise = clockwiseObj.boolValue;

//    switch (self.shapeMode) {
//        case FNShapeModeFlagCorner: {
//            // noop
//        } break;
//        case FNShapeModeFlagCorners: {
//            w = w - x;
//            h = h - y;
//        } break;
//        case FNShapeModeFlagCenter: {
//            x -= w * 0.5;
//            y -= h * 0.5;
//        } break;
//        case FNShapeModeFlagRadius: {
//            x -= w;
//            y -= h;
//            w *= 2.0;
//            h *= 2.0;
//        } break;
//
//        default:
//            TDAssert(0);
//            break;
//    }

    
    [self render:^(CGContextRef ctx, NSInteger strokeWeight) {
        CGContextAddArc(ctx, x, y, radius, startAngle, endAngle, clockwise);
    }];
    
    return nil;
}

@end
