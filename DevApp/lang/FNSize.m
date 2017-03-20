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
    funcSym.params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                      width, @"width",
                      height, @"height",
                      nil];
    
    return funcSym;
}


- (XPObject *)callWithWalker:(XPTreeWalker *)walker argc:(NSUInteger)argc {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *width = [space objectForName:@"width"];
    TDAssert(width);
    
    XPObject *height = [space objectForName:@"height"];
    TDAssert(height);
    
    double w = [width.value doubleValue];
    double h = [height.value doubleValue];
    
    self.canvasGraphicsContext = [[self newContextWithSize:CGSizeMake(w, h)] autorelease];

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
    
    return g;
}

@end
