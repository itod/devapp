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
#import "XPFunctionSymbol.h"
#import "XPMemorySpace.h"

@implementation FNSize

+ (NSString *)name {
    return @"size";
}


- (XPFunctionSymbol *)symbol {
    XPFunctionSymbol *funcSym = [XPFunctionSymbol symbolWithName:[[self class] name] enclosingScope:nil];
    funcSym.nativeBody = self;
    
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


- (XPObject *)callWithWalker:(XPTreeWalker *)walker argc:(NSUInteger)argc {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *w = [space objectForName:@"width"];
    XPObject *h = [space objectForName:@"height"];
    
    if (1 == argc) {
        if (w.isArrayObject && 2 == [w.value count]) {
            NSArray *v = w.value;
            w = [v objectAtIndex:0];
            h = [v objectAtIndex:1];
        } else {
            [self raiseIllegalArgumentException:@"when calling %@() with one argument, argument must be a size Array object: [width, height]", [[self class] name]];
        }
    }
    
    TDAssert(w);
    TDAssert(h);

    self.canvasGraphicsContext = [[self newContextWithSize:CGSizeMake(w.doubleValue, h.doubleValue)] autorelease];

    [self postUpate];
    
    return nil;
}


- (NSGraphicsContext *)newContextWithSize:(CGSize)size {
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
