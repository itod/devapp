//
//  FNEllipseMode.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNEllipseMode.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"
#import "XPNullClass.h"

@implementation FNEllipseMode

+ (NSString *)name {
    return @"ellipseMode";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPNullClass classInstance];
    
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
    
    self.ellipseMode = flag;
    
    return nil;
}

@end
