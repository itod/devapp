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
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNTranslate

+ (NSString *)name {
    return @"translate";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *x = [XPSymbol symbolWithName:@"x"];
    XPSymbol *y = [XPSymbol symbolWithName:@"y"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x, y, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x, @"x",
                      y, @"y",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker argc:(NSUInteger)argc {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *x = [space objectForName:@"x"]; TDAssert(x);
    XPObject *y = [space objectForName:@"y"]; TDAssert(y);
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextTranslateCTM(ctx, x.doubleValue, y.doubleValue);
    
    return nil;
}

@end
