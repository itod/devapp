//
//  EDFaviconController.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 3/31/11.
//  Copyright 2011 Todd Ditchendorf. All rights reserved.
//

#import "EDFaviconController.h"

#ifndef APP_STORE
#import "WebIconDatabase.h"
#endif

//#ifdef APP_STORE
static NSImage *sDefaultFavicon = nil;
//#endif

@implementation EDFaviconController

+ (void)load {
    if ([EDFaviconController class] == self) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [self setUp];
        
        [pool release];
    }
}


+ (void)setUp {
    sDefaultFavicon = [[NSImage imageNamed:@"default_favicon"] retain];
    EDAssert(sDefaultFavicon);
#ifdef APP_STORE
#else
    // initialize WebKit favicon database
    [WebIconDatabase sharedIconDatabase];    
#endif
}


+ (EDFaviconController *)instance {
    EDAssertMainThread();
    static EDFaviconController *instance = nil;
    if (!instance) {
        instance = [[EDFaviconController alloc] init];
    }
    return instance;
}


- (id)init {
    if (self = [super init]) {

    }
    return self;
}


- (void)dealloc {

    [super dealloc];
}


- (NSImage *)defaultFavicon {
    NSImage *img = nil;
//#ifdef APP_STORE
    img = sDefaultFavicon;
//#else
//    img = [[WebIconDatabase sharedIconDatabase] defaultIconWithSize:NSMakeSize(16.0, 16.0)];
//    
////    NSData *data = [img TIFFRepresentation];
////    NSString *path = @"/Users/itod/Desktop/img.tiff";
////    NSError *err = nil;
////    [data writeToFile:path options:NSAtomicWrite error:&err];
////    if (err) {
////        NSLog(@"%@", err);
////    }
//
//#endif
    return img;
}


- (NSImage *)faviconForURL:(NSString *)s {
    NSImage *img = nil;
#ifdef APP_STORE
    img = [self defaultFavicon];
#else
    img = [[WebIconDatabase sharedIconDatabase] iconForURL:s withSize:NSMakeSize(16.0, 16.0)];
#endif
    return img;
}

@end
