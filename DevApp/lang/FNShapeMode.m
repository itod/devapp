//
//  FNShapeMode.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNShapeMode.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNShapeMode

+ (NSString *)name {
    return @"shapeMode";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *mode = [XPSymbol symbolWithName:@"mode"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:mode, nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      mode, @"mode",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *mode = [space objectForName:@"mode"];
    TDAssert(mode);
    
    if (!mode.isNumericObject) {
        [self raise:XPTypeError format:@"invalid shape mode : %@", [mode reprValue]];
        return nil;
    }
    
    FNShapeModeFlag flag = [mode integerValue];
    
    switch (flag) {
        case FNShapeModeFlagCorner:
        case FNShapeModeFlagCorners:
        case FNShapeModeFlagCenter:
        case FNShapeModeFlagRadius:
            // noop
            break;
        default:
            [self raise:XPTypeError format:@"invalid shape mode : %ld", flag];
            return nil;
            break;
    }
    
    self.shapeMode = flag;
    
    return nil;
}

@end
