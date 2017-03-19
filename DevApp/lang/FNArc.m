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

@implementation FNArc

+ (NSString *)name {
    return @"arc";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *x = [XPSymbol symbolWithName:@"x"];
    XPSymbol *y = [XPSymbol symbolWithName:@"y"];
    XPSymbol *radius = [XPSymbol symbolWithName:@"radius"];
    XPSymbol *startAngle = [XPSymbol symbolWithName:@"startAngle"];
    XPSymbol *endAngle = [XPSymbol symbolWithName:@"endAngle"];
    XPSymbol *clockwise = [XPSymbol symbolWithName:@"clockwise"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x, y, radius, startAngle, endAngle, clockwise, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"y",
                                   [XPObject nullObject], @"radius",
                                   [XPObject nullObject], @"startAngle",
                                   [XPObject nullObject], @"endAngle",
                                   [XPObject nullObject], @"clockwise",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x, @"x",
                      y, @"y",
                      radius, @"radius",
                      startAngle, @"startAngle",
                      startAngle, @"startAngle",
                      endAngle, @"endAngle",
                      clockwise, @"clockwise",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker argc:(NSUInteger)argc {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *x = [space objectForName:@"x"]; TDAssert(x);
    XPObject *y = [space objectForName:@"y"]; TDAssert(y);
    XPObject *radius = [space objectForName:@"radius"]; TDAssert(radius);
    XPObject *startAngle = [space objectForName:@"startAngle"]; TDAssert(startAngle);
    XPObject *endAngle = [space objectForName:@"endAngle"]; TDAssert(endAngle);
    XPObject *clockwise = [space objectForName:@"clockwise"]; TDAssert(clockwise);
    
    if (1 == argc) {
        NSArray *v = x.value;
        x = [v objectAtIndex:0];
        y = [v objectAtIndex:1];
        radius = [v objectAtIndex:2];
        startAngle = [v objectAtIndex:3];
        endAngle = [v objectAtIndex:4];
        clockwise = [v objectAtIndex:5];
    }
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    
    CGContextAddArc(ctx, x.doubleValue, y.doubleValue, radius.doubleValue, startAngle.doubleValue, endAngle.doubleValue, clockwise.doubleValue);
    
    [self postUpate];
    
    return nil;
}

@end
