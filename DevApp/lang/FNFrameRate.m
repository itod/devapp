//
//  FNFrameRate.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNFrameRate.h"
#import <Language/XPObject.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"
#import "XPNullClass.h"

@implementation FNFrameRate

+ (NSString *)name {
    return @"frameRate";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPNullClass classInstance];
    
    XPSymbol *frameRate = [XPSymbol symbolWithName:@"frameRate"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:frameRate, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      frameRate, @"frameRate",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *frameRate = [space objectForName:@"frameRate"];

    self.frameRate = [frameRate doubleValue];
    
    return nil;
}

@end
