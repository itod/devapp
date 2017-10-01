//
//  SZApplication.m
//  DevApp
//
//  Created by Todd Ditchendorf on 3/19/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "SZApplication.h"

@interface SZApplication ()
@property (nonatomic, retain) NSMutableDictionary *contextTab;
@property (nonatomic, retain) NSMutableDictionary *imageTab;
@property (nonatomic, retain) NSMutableDictionary *stackTab;
@property (nonatomic, retain) NSMutableDictionary *loopTab;
@property (nonatomic, retain) NSMutableDictionary *redrawTab;
@end

@implementation SZApplication

- (id)init {
    self = [super init];
    if (self) {
        self.contextTab = [NSMutableDictionary dictionary];
        self.imageTab = [NSMutableDictionary dictionary];
        self.stackTab = [NSMutableDictionary dictionary];
        self.loopTab = [NSMutableDictionary dictionary];
        self.redrawTab = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.contextTab = nil;
    self.imageTab = nil;
    self.stackTab = nil;
    self.loopTab = nil;
    self.redrawTab = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (NSGraphicsContext *)graphicsContextForIdentifier:(NSString *)identifier {
    TDAssertExecuteThread();
    TDAssert(_contextTab);
    NSGraphicsContext *g = nil;
    //@synchronized(_contextTab) {
        g = [_contextTab objectForKey:identifier];
    //}
    return g;
}


- (void)setGraphicsContext:(NSGraphicsContext *)g forIdentifier:(NSString *)identifier {
    TDAssertExecuteThread();
    TDAssert([identifier length]);
    TDAssert(_contextTab);
    //@synchronized(_contextTab) {
        if (g) {
            [_contextTab setObject:g forKey:identifier];
        } else {
            [_contextTab removeObjectForKey:identifier];
        }
    //}
}


- (NSImage *)sharedImageForIdentifier:(NSString *)identifier {
    TDAssert(_imageTab);
    NSImage *g = nil;
    @synchronized(_imageTab) {
        g = [_imageTab objectForKey:identifier];
    }
    return g;
}


- (void)setSharedImage:(NSImage *)img forIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_imageTab);
    @synchronized(_imageTab) {
        if (img) {
            [_imageTab setObject:img forKey:identifier];
        } else {
            [_imageTab removeObjectForKey:identifier];
        }
    }
}


- (NSMutableArray *)strokeWeightStackForIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_stackTab);
    id res = nil;
    @synchronized(_stackTab) {
        res = [_stackTab objectForKey:identifier];
    }
    TDAssert(res);
    return res;
}


- (void)setStrokeWeightStack:(NSMutableArray *)stack forIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(stack);
    TDAssert(_stackTab);
    @synchronized(_stackTab) {
        [_stackTab setObject:stack forKey:identifier];
    }
}


- (BOOL)loopForIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_loopTab);
    id val = nil;
    @synchronized(_loopTab) {
       val = [_loopTab objectForKey:identifier];
    }
    TDAssert(val);
    return [val boolValue];
}


- (void)setLoop:(BOOL)yn forIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_loopTab);
    id val = @(yn);
    @synchronized(_loopTab) {
        [_loopTab setObject:val forKey:identifier];
    }
}


- (BOOL)redrawForIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_redrawTab);
    id val = nil;
    @synchronized(_redrawTab) {
        val = [_redrawTab objectForKey:identifier];
    }
    TDAssert(val);
    return [val boolValue];
}


- (void)setRedraw:(BOOL)yn forIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_redrawTab);
    id val = @(yn);
    @synchronized(_redrawTab) {
        [_redrawTab setObject:val forKey:identifier];
    }
}

@end
