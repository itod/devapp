//
//  FNScale.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNScale.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNScale

+ (NSString *)name {
    return @"scale";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *x = [XPSymbol symbolWithName:@"x"];
    XPSymbol *y = [XPSymbol symbolWithName:@"y"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x, y, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"y",
                                   nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @1.0, @"y",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x, @"x",
                      y, @"y",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker argc:(NSUInteger)argc {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *x = [space objectForName:@"x"];
    XPObject *y = [space objectForName:@"y"];
    
    if (1 == argc) {
        if (x.isArrayObject && 2 == [x.value count]) {
            NSArray *v = x.value;
            x = [v objectAtIndex:0];
            y = [v objectAtIndex:1];
        } else {
            [self raiseIllegalArgumentException:@"when calling %@() with one argument, argument must be a size Array object: [width, height]", [[self class] name]];
        }
    }
    
    TDAssert(x);
    TDAssert(y);
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextScaleCTM(ctx, x.doubleValue, y.doubleValue);
    
    return nil;
}

@end
