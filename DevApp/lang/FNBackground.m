//
//  FNBackground.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNBackground.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNBackground

+ (NSString *)name {
    return @"background";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *color = [XPSymbol symbolWithName:@"color"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:color, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      color, @"color",
                      nil];
    
    [funcSym setDefaultObject:[XPObject trueObject] forParamNamed:@"color"]; // default is white
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *colorObj = [space objectForName:@"color"]; TDAssert(colorObj);

    NSColor *c = [self asColor:colorObj];
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    
    CGContextSaveGState(ctx); {
        CGContextSetRGBFillColor(ctx, [c redComponent], [c greenComponent], [c blueComponent], [c alphaComponent]);
        CGRect r = CGRectMake(0.0, 0.0, CGBitmapContextGetWidth(ctx), CGBitmapContextGetHeight(ctx));
        CGContextFillRect(ctx, r);
    } CGContextRestoreGState(ctx);

    return nil;
}

@end
