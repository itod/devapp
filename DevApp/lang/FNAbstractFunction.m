//
//  FNAbstractFunction.m
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNAbstractFunction.h"
#import "EDApplication.h"

@implementation FNAbstractFunction

- (NSGraphicsContext *)canvasGraphicsContext {
    return [[EDApplication instance] canvasGraphicsContext];
}


- (void)setCanvasGraphicsContext:(NSGraphicsContext *)g {
    [[EDApplication instance] setCanvasGraphicsContext:g];
}


- (void)postUpate {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:@"CanvasDidUpdateNotification" object:nil];
}

@end
