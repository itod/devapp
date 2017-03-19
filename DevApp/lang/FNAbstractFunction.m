//
//  FNAbstractFunction.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNAbstractFunction.h"
#import "EDApplication.h"
#import <Language/XPObject.h>
#import <TDAppKit/TDUtils.h>

@implementation FNAbstractFunction

- (void)postUpate {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"CanvasDidUpdateNotification" object:nil];
}


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


#pragma mark -
#pragma mark Properties

- (NSGraphicsContext *)canvasGraphicsContext {
    return [[EDApplication instance] canvasGraphicsContext];
}


- (void)setCanvasGraphicsContext:(NSGraphicsContext *)g {
    [[EDApplication instance] setCanvasGraphicsContext:g];
}


- (NSMutableArray *)lineWidthStack {
    return [[EDApplication instance] lineWidthStack];
}

@end
