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
    
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (NSGraphicsContext *)graphicsContextForIdentifier:(NSString *)identifer {
    TDAssert(_contextTab);
    return [_contextTab objectForKey:identifer];
}


- (void)setGraphicsContext:(NSGraphicsContext *)g forIdentifier:(NSString *)identifer {
    TDAssert([identifer length]);
    TDAssert(_contextTab);
    [_contextTab setObject:g forKey:identifer];
}


- (NSMutableArray *)strokeWeightStackForIdentifier:(NSString *)identifer {
    TDAssert(_stackTab);
    TDAssert([identifer length]);
    id res = [_stackTab objectForKey:identifer];
    TDAssert(res);
    return res;
}


- (void)setStrokeWeightStack:(NSMutableArray *)stack forIdentifier:(NSString *)identifer {
    TDAssert(stack);
    TDAssert([identifer length]);
    TDAssert(_stackTab);
    [_stackTab setObject:stack forKey:identifer];
}

@end
