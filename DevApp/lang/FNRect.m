//
//  FNRect.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNRect.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNRect

+ (NSString *)name {
    return @"rect";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
    XPSymbol *x = [XPSymbol symbolWithName:@"x"];
    XPSymbol *y = [XPSymbol symbolWithName:@"y"];
    XPSymbol *width = [XPSymbol symbolWithName:@"width"];
    XPSymbol *height = [XPSymbol symbolWithName:@"height"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:x, y, width, height, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"y",
                                   [XPObject nullObject], @"width",
                                   [XPObject nullObject], @"height",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      x, @"x",
                      y, @"y",
                      width, @"width",
                      height, @"height",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *x = [space objectForName:@"x"];
    XPObject *y = [space objectForName:@"y"];
    XPObject *w = [space objectForName:@"width"];
    XPObject *h = [space objectForName:@"height"];
    
    if (1 == argc) {
        if (x.isArrayObject && 4 == [x.value count]) {
            NSArray *v = x.value;
            x = [v objectAtIndex:0];
            y = [v objectAtIndex:1];
            w = [v objectAtIndex:2];
            h = [v objectAtIndex:3];
        } else {
            [self raise:XPTypeError format:@"when calling `%@()` with one argument, argument must be a rectangle Array object: [x, y, width, height]", [[self class] name]];
        }
    }
    
    TDAssert(x);
    TDAssert(y);
    TDAssert(w);
    TDAssert(h);
    
    [self render:^(CGContextRef ctx) {
        // FILL
        {
            CGRect fillRect = CGRectMake(x.doubleValue, y.doubleValue, w.doubleValue, h.doubleValue);
            CGContextFillRect(ctx, fillRect);
        }
        
        // STROKE
        {
            NSInteger weight = [[self.strokeWeightStack lastObject] integerValue];
            if (weight > 0) {
                CGRect strokeRect;
                
                BOOL isOdd = (weight & 1);
                if (isOdd) {
                    strokeRect = CGRectMake(x.doubleValue+0.5, y.doubleValue+0.5, w.doubleValue, h.doubleValue);
                } else {
                    strokeRect = CGRectMake(x.doubleValue, y.doubleValue, w.doubleValue, h.doubleValue);
                }
                
                CGContextStrokeRect(ctx, strokeRect);
            }
        }
    }];
    
    return nil;
}

@end
