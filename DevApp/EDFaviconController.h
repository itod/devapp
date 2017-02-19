//
//  EDFaviconController.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 3/31/11.
//  Copyright 2011 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EDFaviconController : NSObject

+ (void)setUp;
+ (EDFaviconController *)instance;

- (NSImage *)defaultFavicon;
- (NSImage *)faviconForURL:(NSString *)s;
@end
