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
@property (nonatomic, retain) NSMutableDictionary *stackTab;
@property (nonatomic, retain) NSMutableDictionary *loopTab;
@end

@implementation SZApplication

- (id)init {
    self = [super init];
    if (self) {
        self.contextTab = [NSMutableDictionary dictionary];
        self.stackTab = [NSMutableDictionary dictionary];
        self.loopTab = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.contextTab = nil;
    self.stackTab = nil;
    self.loopTab = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (NSGraphicsContext *)graphicsContextForIdentifier:(NSString *)identifier {
    TDAssert(_contextTab);
    NSGraphicsContext *g = nil;
    @synchronized(_contextTab) {
        g = [_contextTab objectForKey:identifier];
    }
    return g;
}


- (void)setGraphicsContext:(NSGraphicsContext *)g forIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_contextTab);
    @synchronized(_contextTab) {
        [_contextTab setObject:g forKey:identifier];
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

@end
