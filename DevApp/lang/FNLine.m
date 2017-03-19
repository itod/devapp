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
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

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
    
    XPObject *x1 = [space objectForName:@"x1"]; TDAssert(x1);
    XPObject *y1 = [space objectForName:@"y1"]; TDAssert(y1);
    XPObject *x2 = [space objectForName:@"x2"]; TDAssert(x2);
    XPObject *y2 = [space objectForName:@"y2"]; TDAssert(y2);
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    
    CGContextMoveToPoint(ctx, x1.doubleValue, y1.doubleValue);
    CGContextAddLineToPoint(ctx, x2.doubleValue, y2.doubleValue);
    
    [self postUpate];
    
    return nil;
}

@end
