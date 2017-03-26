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
                        @(0xFF0000), @"red",
                        @(0x800000), @"maroon",
                        @(0xFFFF00), @"yellow",
                        @(0x808000), @"olive",
                        @(0x00FF00), @"lime",
                        @(0x008000), @"green",
                        @(0x00FFFF), @"aqua",
                        @(0x008080), @"teal",
                        @(0x0000FF), @"blue",
                        @(0x000080), @"navy",
                        @(0xFF00FF), @"fuchsia",
                        @(0x800080), @"purple",
                        nil];
        }
        
        NSString *name = [obj.stringValue lowercaseString];
        NSNumber *n = [sColors objectForKey:name];
        if (n) {
            c = TDHexColor([n doubleValue]);
        } else {
            @throw @"TODO";
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
                double r = [obj.value[0] doubleValue];
                double g = [obj.value[1] doubleValue];
                double b = [obj.value[2] doubleValue];
                c = [NSColor colorWithRed:r green:g blue:b alpha:1.0];
            } break;
                
            case 4: {
                double r = [obj.value[0] doubleValue];
                double g = [obj.value[1] doubleValue];
                double b = [obj.value[2] doubleValue];
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
                double r = [obj.value[@"r"] doubleValue];
                double g = [obj.value[@"g"] doubleValue];
                double b = [obj.value[@"b"] doubleValue];
                c = [NSColor colorWithRed:r green:g blue:b alpha:1.0];
            } break;
                
            case 4: {
                double r = [obj.value[@"r"] doubleValue];
                double g = [obj.value[@"g"] doubleValue];
                double b = [obj.value[@"b"] doubleValue];
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
    
    return c;
}


- (void)postUpate {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"CanvasDidUpdateNotification" object:[[self class] identifier]];
}


- (void)raiseIllegalArgumentException:fmt, ... {
    va_list vargs;
    va_start(vargs, fmt);
    
    NSString *msg = [[[NSString alloc] initWithFormat:fmt arguments:vargs] autorelease];
    
    va_end(vargs);
    
    XPException *ex = [[[XPException alloc] initWithName:XPExceptionIllegalArgument reason:msg userInfo:nil] autorelease];
    [ex raise];
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

    [[SZApplication instance] setStrokeWeightStack:[NSMutableArray arrayWithObject:@1] forIdentifier:identifier];
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

@end
