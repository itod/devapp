//
//  FNStrokeCap.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNStrokeCap.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNStrokeCap

+ (NSString *)name {
    return @"strokeCap";
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
    
    CGLineCap cap = kCGLineCapRound;
    if ([@"round" isEqualToString:type]) {
        cap = kCGLineCapRound;
    } else if ([@"square" isEqualToString:type]) {
        cap = kCGLineCapButt;
    } else if ([@"project" isEqualToString:type]) {
        cap = kCGLineCapSquare;
    }
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    CGContextSetLineCap(ctx, cap);
    
    return nil;
}

@end
