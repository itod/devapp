//
//  SZApplication.m
//  DevApp
//
//  Created by Todd Ditchendorf on 3/19/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "SZApplication.h"
#import "TDUtils.h"

NSString * const SZGraphicsContextDidChangeSizeNotification = @"SZGraphicsContextDidChangeSizeNotification";

@interface SZApplication ()
@property (nonatomic, retain) NSMutableDictionary *contextTab;
@property (nonatomic, retain) NSMutableDictionary *imageTab;
@property (nonatomic, retain) NSMutableDictionary *stackTab;
@property (nonatomic, retain) NSMutableDictionary *loopTab;
@property (nonatomic, retain) NSMutableDictionary *redrawTab;
@property (nonatomic, retain) NSMutableDictionary *frameRateTab;
@property (nonatomic, retain) NSMutableDictionary *shapeModeTab;
@end

@implementation SZApplication

- (instancetype)init {
    self = [super init];
    if (self) {
        self.contextTab = [NSMutableDictionary dictionary];
        self.imageTab = [NSMutableDictionary dictionary];
        self.stackTab = [NSMutableDictionary dictionary];
        self.loopTab = [NSMutableDictionary dictionary];
        self.redrawTab = [NSMutableDictionary dictionary];
        self.frameRateTab = [NSMutableDictionary dictionary];
        self.shapeModeTab = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.contextTab = nil;
    self.imageTab = nil;
    self.stackTab = nil;
    self.loopTab = nil;
    self.redrawTab = nil;
    self.frameRateTab = nil;
    self.shapeModeTab = nil;
    [super dealloc];
}


- (void)notifyLater:(NSString *)identifier {
    TDPerformOnMainThread(^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyNow:) object:identifier];
        [self performSelector:@selector(notifyNow:) withObject:identifier afterDelay:0.05];
    });
}


- (void)notifyNow:(NSString *)identifier {
    TDAssertMainThread();
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:SZGraphicsContextDidChangeSizeNotification object:identifier];
}


#pragma mark -
#pragma mark Public

- (NSGraphicsContext *)graphicsContextForIdentifier:(NSString *)identifier {
    TDAssertExecuteThread();
    TDAssert(_contextTab);
    NSGraphicsContext *g = [_contextTab objectForKey:identifier];
    return g;
}


- (void)setGraphicsContext:(NSGraphicsContext *)g forIdentifier:(NSString *)identifier {
    TDAssertExecuteThread();
    TDAssert([identifier length]);
    TDAssert(_contextTab);
    if (g) {
        [_contextTab setObject:g forKey:identifier];
    } else {
        [_contextTab removeObjectForKey:identifier];
    }

    [self notifyLater:identifier];
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


- (double)frameRateForIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_frameRateTab);
    id val = nil;
    @synchronized(_frameRateTab) {
        val = [_frameRateTab objectForKey:identifier];
    }
    TDAssert(val);
    return [val doubleValue];
}


- (void)setFrameRate:(double)frameRate forIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_frameRateTab);
    id val = @(frameRate);
    @synchronized(_frameRateTab) {
        [_frameRateTab setObject:val forKey:identifier];
    }
}


- (NSInteger)shapeModeForIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_shapeModeTab);
    id val = nil;
    @synchronized(_shapeModeTab) {
        val = [_shapeModeTab objectForKey:identifier];
    }
    TDAssert(val);
    return [val doubleValue];
}


- (void)setShapeMode:(NSInteger)shapeMode forIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_shapeModeTab);
    id val = @(shapeMode);
    @synchronized(_shapeModeTab) {
        [_shapeModeTab setObject:val forKey:identifier];
    }
}

@end
