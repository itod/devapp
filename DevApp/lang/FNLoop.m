//
//  FNLoop.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNLoop.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"
#import "XPNullClass.h"

@implementation FNLoop

+ (NSString *)name {
    return @"loop";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPNullClass classInstance];

    XPSymbol *yn = [XPSymbol symbolWithName:@"shouldLoop"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:yn, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      yn, @"shouldLoop",
                      nil];
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *yn = [space objectForName:@"shouldLoop"];
    self.loop = [yn boolValue];
    return nil;
}

@end
