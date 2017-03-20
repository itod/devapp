//
//  FNEllipse.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNEllipse.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNEllipse

+ (NSString *)name {
    return @"ellipse";
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


- (XPObject *)callWithWalker:(XPTreeWalker *)walker argc:(NSUInteger)argc {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *x = [space objectForName:@"x"]; TDAssert(x);
    XPObject *y = [space objectForName:@"y"]; TDAssert(y);
    XPObject *w = [space objectForName:@"width"]; TDAssert(w);
    XPObject *h = [space objectForName:@"height"]; TDAssert(h);
    
    if (1 == argc) {
        NSArray *v = x.value;
        x = [v objectAtIndex:0];
        y = [v objectAtIndex:1];
        w = [v objectAtIndex:2];
        h = [v objectAtIndex:3];
    }
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];
    
    // FILL
    {
        CGRect fillRect = CGRectMake(x.doubleValue, y.doubleValue, w.doubleValue, h.doubleValue);
        CGContextFillEllipseInRect(ctx, fillRect);
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
            
            CGContextStrokeEllipseInRect(ctx, strokeRect);
        }
    }
    
    [self postUpate];
    
    return nil;
}

@end
