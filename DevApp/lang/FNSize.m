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

#import "EDApplication.h"

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


- (XPObject *)callWithWalker:(XPTreeWalker *)walker {
    XPMemorySpace *space = walker.currentSpace;
    TDAssert(space);
    
    XPObject *width = [space objectForName:@"width"];
    TDAssert(width);
    
    XPObject *height = [space objectForName:@"height"];
    TDAssert(height);
    
    double w = [width.value doubleValue];
    double h = [height.value doubleValue];
    
    NSGraphicsContext *g = [[self newContextWithSize:CGSizeMake(w, h)] autorelease];
    
    [[EDApplication instance] setCanvasGraphicsContext:g];
    
    return nil;
}


- (NSGraphicsContext *)newContextWithSize:(CGSize)size {
    CGRect imgRect = NSMakeRect(0.0, 0.0, size.width, size.height);
    CGSize imgSize = imgRect.size;
    
    NSBitmapImageRep *offscreenRep = [[[NSBitmapImageRep alloc]
                                       initWithBitmapDataPlanes:NULL
                                       pixelsWide:imgSize.width
                                       pixelsHigh:imgSize.height
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
    return g;
}

@end
