//
//  FNAbstractFunction.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNAbstractFunction.h"
#import "SZApplication.h"
#import <Language/XPObject.h>
#import <Language/XPException.h>
#import <TDAppKit/TDUtils.h>

NSString * const FNCanvasDidDebugUpdateNotification = @"FNCanvasDidDebugUpdateNotification";

@implementation FNAbstractFunction

- (NSColor *)asColor:(XPObject *)obj {
    NSColor *c = nil;
    
    if (obj.isBooleanObject) {
        c = [obj boolValue] ? [NSColor whiteColor] : [NSColor blackColor];
    } else if (obj.isNumericObject) {
        double x = obj.doubleValue;
        if (x > 0xFFFFFF) {
            c = TDHexaColor(x);
        } else {
            c = TDHexColor(x);
        }
    } else if (obj.isStringObject) {
        
        static NSDictionary *sColors = nil;
        if (!sColors) {
            sColors = [[NSDictionary alloc] initWithObjectsAndKeys:
                        @(0xFFFFFF), @"white",
                        @(0xC0C0C0), @"silver",
                        @(0x808080), @"gray",
                        @(0x000000), @"black",
                        @(0xFF80FF), @"pink",
                        @(0xFF0000), @"red",
                        @(0x800000), @"maroon",
                        @(0xFF8000), @"orange",
                        @(0xFFFF00), @"yellow",
                        @(0x808000), @"olive",
                        @(0x00FF00), @"lime",
                        @(0x008000), @"green",
                        @(0x00FFFF), @"aqua",
                        @(0x008080), @"teal",
                        @(0x0000FF), @"blue",
                        @(0x000080), @"navy",
                        @(0xFF00FF), @"fuchsia",
                        @(0xFF00FF), @"magenta",
                        @(0x800080), @"purple",
                        nil];
        }
        
        NSString *name = [obj.stringValue lowercaseString];
        NSNumber *n = [sColors objectForKey:name];
        if (n) {
            c = TDHexColor([n doubleValue]);
        } else {
            TDAssert(0);
            c = [NSColor blackColor];
        }
    } else if (obj.isArrayObject) {
        NSUInteger argc = [obj.value count];
        
        switch (argc) {
            case 1: {
                double white = [obj.value[0] doubleValue];
                c = [NSColor colorWithWhite:white alpha:1.0];
            } break;

            case 2: {
                double white = [obj.value[0] doubleValue];
                double alpha = [obj.value[1] doubleValue];
                c = [NSColor colorWithWhite:white alpha:alpha];
            } break;
                
            case 3: {
                double r = [obj.value[0] doubleValue]/255.0;
                double g = [obj.value[1] doubleValue]/255.0;
                double b = [obj.value[2] doubleValue];
                c = [NSColor colorWithRed:r green:g blue:b alpha:1.0];
            } break;
                
            case 4: {
                double r = [obj.value[0] doubleValue]/255.0;
                double g = [obj.value[1] doubleValue]/255.0;
                double b = [obj.value[2] doubleValue]/255.0;
                double a = [obj.value[3] doubleValue];
                c = [NSColor colorWithRed:r green:g blue:b alpha:a];
            } break;
                
            default:
                @throw @"TODO";
                break;
        }
    } else if (obj.isDictionaryObject) {
        NSUInteger argc = [obj.value count];
        
        switch (argc) {
            case 1: {
                double white = [obj.value[@"gray"] doubleValue];
                c = [NSColor colorWithWhite:white alpha:1.0];
            } break;
                
            case 2: {
                double white = [obj.value[@"gray"] doubleValue];
                double alpha = [obj.value[@"alpha"] doubleValue];
                c = [NSColor colorWithWhite:white alpha:alpha];
            } break;
                
            case 3: {
                double r = [obj.value[@"r"] doubleValue]/255.0;
                double g = [obj.value[@"g"] doubleValue]/255.0;
                double b = [obj.value[@"b"] doubleValue]/255.0;
                c = [NSColor colorWithRed:r green:g blue:b alpha:1.0];
            } break;
                
            case 4: {
                double r = [obj.value[@"r"] doubleValue]/255.0;
                double g = [obj.value[@"g"] doubleValue]/255.0;
                double b = [obj.value[@"b"] doubleValue]/255.0;
                double a = [obj.value[@"a"] doubleValue];
                c = [NSColor colorWithRed:r green:g blue:b alpha:a];
            } break;
                
            default:
                @throw @"TODO";
                break;
        }
    } else {
        @throw @"TODO";
    }
    
    return [c colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
}


- (void)render:(FNRenderBlock)block {
    TDAssert(block);
    
    CGContextRef ctx = [self.canvasGraphicsContext graphicsPort];

    NSInteger strokeWeight = [[self.strokeWeightStack lastObject] integerValue];
    
    CGContextSaveGState(ctx); {
        BOOL isOdd = (strokeWeight & 1);
        if (isOdd) {
            CGContextTranslateCTM(ctx, 0.5, 0.5);
        }
        
        block(ctx, strokeWeight);
    } CGContextRestoreGState(ctx);
    
    [self postCanvasDebugUpdate];
}


- (void)postCanvasDebugUpdate {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:FNCanvasDidDebugUpdateNotification object:[[self class] identifier]];
}


- (CGRect)rectWithX:(double)x y:(double)y width:(double)w height:(double)h mode:(FNShapeModeFlag)mode {
    switch (mode) {
        case FNShapeModeFlagCorner: {
            // noop
        } break;
        case FNShapeModeFlagCorners: {
            w = w - x;
            h = h - y;
        } break;
        case FNShapeModeFlagCenter: {
            x -= w * 0.5;
            y -= h * 0.5;
        } break;
        case FNShapeModeFlagRadius: {
            x -= w;
            y -= h;
            w *= 2.0;
            h *= 2.0;
        } break;
            
        default:
            TDAssert(0);
            break;
    }

    return CGRectMake(x, y, w, h);
}


#pragma mark -
#pragma mark Properties

+ (NSString *)identifier {
    return [[[NSThread currentThread] threadDictionary] objectForKey:@"EDIdentifier"];
}


+ (void)setIdentifier:(NSString *)identifier {
    TDAssertExecuteThread();
    TDAssert([identifier length]);
    [[[NSThread currentThread] threadDictionary] setObject:identifier forKey:@"EDIdentifier"];

    [[SZApplication instance] setStrokeWeightStack:[NSMutableArray arrayWithObject:@1] forIdentifier:identifier]; // default is 1
    [[SZApplication instance] setLoop:YES forIdentifier:identifier]; // default is YES
    [[SZApplication instance] setFrameRate:60.0 forIdentifier:identifier]; // default is 60 fps
    [[SZApplication instance] setShapeMode:FNShapeModeFlagCorner forIdentifier:identifier]; // default is CORNER
}


- (NSGraphicsContext *)canvasGraphicsContext {
    TDAssertExecuteThread();
    return [[SZApplication instance] graphicsContextForIdentifier:[[self class] identifier]];
}


- (void)setCanvasGraphicsContext:(NSGraphicsContext *)g {
    TDAssertExecuteThread();
    [[SZApplication instance] setGraphicsContext:g forIdentifier:[[self class] identifier]];
}


- (NSMutableArray *)strokeWeightStack {
    TDAssertExecuteThread();
    return [[SZApplication instance] strokeWeightStackForIdentifier:[[self class] identifier]];
}


- (BOOL)loop {
    TDAssertExecuteThread();
    return [[SZApplication instance] loopForIdentifier:[[self class] identifier]];
}


- (void)setLoop:(BOOL)yn {
    TDAssertExecuteThread();
    [[SZApplication instance] setLoop:yn forIdentifier:[[self class] identifier]];
}


- (BOOL)redraw {
    TDAssertExecuteThread();
    return [[SZApplication instance] redrawForIdentifier:[[self class] identifier]];
}


- (void)setRedraw:(BOOL)yn {
    TDAssertExecuteThread();
    [[SZApplication instance] setRedraw:yn forIdentifier:[[self class] identifier]];
}


- (double)frameRate {
    TDAssertExecuteThread();
    return [[SZApplication instance] frameRateForIdentifier:[[self class] identifier]];
}


- (void)setFrameRate:(double)frameRate {
    TDAssertExecuteThread();
    [[SZApplication instance] setFrameRate:frameRate forIdentifier:[[self class] identifier]];
}


- (FNShapeModeFlag)shapeMode {
    TDAssertExecuteThread();
    return [[SZApplication instance] shapeModeForIdentifier:[[self class] identifier]];
}


- (void)setShapeMode:(FNShapeModeFlag)shapeMode {
    TDAssertExecuteThread();
    [[SZApplication instance] setShapeMode:shapeMode forIdentifier:[[self class] identifier]];
}

@end
