//
//  FNStrokeWeight.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNStrokeWeight.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNStrokeWeight

+ (NSString *)name {
    return @"strokeWeight";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *weight = [XPSymbol symbolWithName:@"weight"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:weight, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      weight, @"weight",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *weightObj = [space objectForName:@"weight"]; TDAssert(weightObj);
    double weight = weightObj.doubleValue;
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextSetLineWidth(ctx, weight);
    
    [self.strokeWeightStack removeLastObject];
    [self.strokeWeightStack addObject:@(weight)];

    return nil;
}

@end
