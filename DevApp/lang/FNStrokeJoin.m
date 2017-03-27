//
//  FNStrokeJoin.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNStrokeJoin.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNStrokeJoin

+ (NSString *)name {
    return @"strokeJoin";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *type = [XPSymbol symbolWithName:@"type"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:type, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      type, @"type",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *typeObj = [space objectForName:@"type"]; TDAssert(typeObj);
    NSString *type = [typeObj.stringValue lowercaseString];
    
    CGLineJoin join = kCGLineJoinMiter;
    if ([@"round" isEqualToString:type]) {
        join = kCGLineJoinRound;
    } else if ([@"miter" isEqualToString:type]) {
        join = kCGLineJoinMiter;
    } else if ([@"bevel" isEqualToString:type]) {
        join = kCGLineJoinBevel;
    }
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextSetLineJoin(ctx, join);
    
    return nil;
}

@end
