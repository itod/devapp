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
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNScale

+ (NSString *)name {
    return @"scale";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *width = [XPSymbol symbolWithName:@"width"];
    XPSymbol *height = [XPSymbol symbolWithName:@"height"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:width, height, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject number:1.0], @"height",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      width, @"width",
                      height, @"height",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker argc:(NSUInteger)argc {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *w = [space objectForName:@"width"];
    XPObject *h = [space objectForName:@"height"];
    
    if (1 == argc) {
        if (w.isArrayObject && 2 == [w.value count]) {
            NSArray *v = w.value;
            w = [v objectAtIndex:0];
            h = [v objectAtIndex:1];
        } else {
            [self raise:XPTypeError format:@"when calling `%@()` with one argument, argument must be a size Array object: [width, height]", [[self class] name]];
        }
    }
    
    TDAssert(w);
    TDAssert(h);
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextScaleCTM(ctx, w.doubleValue, h.doubleValue);
    
    return nil;
}

@end
