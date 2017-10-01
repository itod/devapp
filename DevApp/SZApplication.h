//
//  SZApplication.h
//  DevApp
//
//  Created by Todd Ditchendorf on 3/19/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDApplication.h"

@interface SZApplication : EDApplication

- (NSGraphicsContext *)graphicsContextForIdentifier:(NSString *)identifier;
- (void)setGraphicsContext:(NSGraphicsContext *)g forIdentifier:(NSString *)identifier;

- (NSImage *)sharedImageForIdentifier:(NSString *)identifier;
- (void)setSharedImage:(NSImage *)img forIdentifier:(NSString *)identifier;

- (NSMutableArray *)strokeWeightStackForIdentifier:(NSString *)identifier;
- (void)setStrokeWeightStack:(NSMutableArray *)stack forIdentifier:(NSString *)identifier;

- (BOOL)loopForIdentifier:(NSString *)identifier;
- (void)setLoop:(BOOL)yn forIdentifier:(NSString *)identifier;

- (BOOL)redrawForIdentifier:(NSString *)identifier;
- (void)setRedraw:(BOOL)yn forIdentifier:(NSString *)identifier;

@end
