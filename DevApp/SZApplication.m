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
@end

@implementation SZApplication

- (id)init {
    self = [super init];
    if (self) {
        self.contextTab = [NSMutableDictionary dictionary];
        self.stackTab = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)dealloc {
    self.contextTab = nil;
    self.stackTab = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (NSGraphicsContext *)graphicsContextForIdentifier:(NSString *)identifier {
    TDAssert(_contextTab);
    return [_contextTab objectForKey:identifier];
}


- (void)setGraphicsContext:(NSGraphicsContext *)g forIdentifier:(NSString *)identifier {
    TDAssert([identifier length]);
    TDAssert(_contextTab);
    [_contextTab setObject:g forKey:identifier];
}


- (NSMutableArray *)strokeWeightStackForIdentifier:(NSString *)identifier {
    TDAssert(_stackTab);
    TDAssert([identifier length]);
    id res = [_stackTab objectForKey:identifier];
    TDAssert(res);
    return res;
}


- (void)setStrokeWeightStack:(NSMutableArray *)stack forIdentifier:(NSString *)identifier {
    TDAssert(stack);
    TDAssert([identifier length]);
    TDAssert(_stackTab);
    [_stackTab setObject:stack forKey:identifier];
}

@end
