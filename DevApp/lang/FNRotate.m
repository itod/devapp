//
//  FNRotate.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNRotate.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"
#import "XPNullClass.h"

@implementation FNRotate

+ (NSString *)name {
    return @"rotate";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPNullClass classInstance];
    
    XPSymbol *radians = [XPSymbol symbolWithName:@"radians"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:radians, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      radians, @"radians",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *radians = [space objectForName:@"radians"]; TDAssert(radians);
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextRotateCTM(ctx, radians.doubleValue);
    
    return nil;
}

@end
