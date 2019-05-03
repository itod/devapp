//
//  FNTranslate.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNTranslate.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"
#import "XPNullClass.h"

@implementation FNTranslate

+ (NSString *)name {
    return @"translate";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPNullClass classInstance];
    
    XPSymbol *x = [XPSymbol symbolWithName:@"x"];
    XPSymbol *y = [XPSymbol symbolWithName:@"y"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x, y, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"y",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x, @"x",
                      y, @"y",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *x = [space objectForName:@"x"];
    XPObject *y = [space objectForName:@"y"];
    
    if (1 == argc) {
        if (x.isArrayObject && 2 == [x.value count]) {
            NSArray *v = x.value;
            x = [v objectAtIndex:0];
            y = [v objectAtIndex:1];
        } else {
            [self raise:XPTypeError format:@"when calling `%@()` with one argument, argument must be a size Array object: [width, height]", [[self class] name]];
        }
    }
    
    TDAssert(x);
    TDAssert(y);

    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextTranslateCTM(ctx, x.doubleValue, y.doubleValue);
    
    return nil;
}

@end
