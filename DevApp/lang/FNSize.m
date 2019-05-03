//
//  FNSize.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNSize.h"
#import <Language/XPObject.h>
#import <Language/XPTreeWalker.h>
#import <Language/XPException.h>
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"
#import "SZApplication.h"
#import "XPNullClass.h"

@implementation FNSize

+ (NSString *)name {
    return @"size";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    funcSym.returnType = [XPNullClass classInstance];
    
    XPSymbol *width = [XPSymbol symbolWithName:@"width"];
    XPSymbol *height = [XPSymbol symbolWithName:@"height"];
    funcSym.orderedParams = [NSMutableArray arrayWithObjects:width, height, nil];
    funcSym.defaultParamObjects = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [XPObject nullObject], @"height",
                                   nil];
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      width, @"width",
                      height, @"height",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker functionSpace:(XPMemorySpace *)space argc:(NSUInteger)argc {
    XPObject *w = [space objectForName:@"width"];
    XPObject *h = [space objectForName:@"height"];
    
    if (1 == argc) {
        if (w.isArrayObject && 2 == [w.value count]) {
            NSArray *v = w.value;
            w = [v objectAtIndex:0];
            h = [v objectAtIndex:1];
        } else {
            [self raise:XPTypeError format:@"when calling `%@()` with one argument, argument must be a size Array object: [width, height]", [[self class] name]];
        }
    }
    
    TDAssert(w);
    TDAssert(h);
    
    CGSize size = CGSizeMake(w.doubleValue, h.doubleValue);
    [[self class] setupCanvasWithSize:size globals:walker.globals];
    
    return nil;
}


+ (void)setupCanvasWithSize:(CGSize)size globals:(XPMemorySpace *)globals {
    TDAssertExecuteThread();
    TDAssert(globals);
    
    [globals setObject:[XPObject number:size.width] forName:@"width"];
    [globals setObject:[XPObject number:size.height] forName:@"height"];

    NSGraphicsContext *g = [[self newGraphicsContextWithSize:size] autorelease];
    [[SZApplication instance] setGraphicsContext:g forIdentifier:[self identifier]];
}


+ (NSGraphicsContext *)newGraphicsContextWithSize:(CGSize)size {
    NSBitmapImageRep *offscreenRep = [[[NSBitmapImageRep alloc]
                                       initWithBitmapDataPlanes:NULL
                                       pixelsWide:size.width
                                       pixelsHigh:size.height
                                       bitsPerSample:8
                                       samplesPerPixel:4
                                       hasAlpha:YES
                                       isPlanar:NO
                                       colorSpaceName:NSDeviceRGBColorSpace
                                       bitmapFormat:NSBitmapFormatAlphaFirst
                                       bytesPerRow:0
                                       bitsPerPixel:0] autorelease];
    
    // set offscreen context
    NSGraphicsContext *g = [[NSGraphicsContext graphicsContextWithBitmapImageRep:offscreenRep] retain];
    
    // flip
    CGContextRef ctx = [g graphicsPort];
    CGAffineTransform flip = CGAffineTransformScale(CGAffineTransformMakeTranslation(0.0, size.height), 1.0, -1.0);
    CGContextConcatCTM(ctx, flip);
    
    CGContextSetGrayFillColor(ctx, 1.0, 1.0);
    CGContextSetGrayStrokeColor(ctx, 0.0, 1.0);
    
    CGContextSetLineCap(ctx, kCGLineCapButt);
    CGContextSetLineJoin(ctx, kCGLineJoinMiter);
    
    return g;
}

@end
