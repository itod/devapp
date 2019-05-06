//
//  SZApplication.h
//  DevApp
//
//  Created by Todd Ditchendorf on 3/19/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDApplication.h"

extern NSString * const SZGraphicsContextDidChangeSizeNotification;

@interface SZApplication : EDApplication

- (NSGraphicsContext *)graphicsContextForIdentifier:(NSString *)identifier;
- (void)setGraphicsContext:(NSGraphicsContext *)g forIdentifier:(NSString *)identifier;

- (NSImage *)sharedImageForIdentifier:(NSString *)identifier;
- (void)setSharedImage:(NSImage *)img forIdentifier:(NSString *)identifier;

- (NSMutableArray *)noFillStackForIdentifier:(NSString *)identifier;
- (void)setNoFillStack:(NSMutableArray *)stack forIdentifier:(NSString *)identifier;

- (NSMutableArray *)noStrokeStackForIdentifier:(NSString *)identifier;
- (void)setNoStrokeStack:(NSMutableArray *)stack forIdentifier:(NSString *)identifier;

- (NSMutableArray *)strokeWeightStackForIdentifier:(NSString *)identifier;
- (void)setStrokeWeightStack:(NSMutableArray *)stack forIdentifier:(NSString *)identifier;

- (BOOL)loopForIdentifier:(NSString *)identifier;
- (void)setLoop:(BOOL)yn forIdentifier:(NSString *)identifier;

- (BOOL)redrawForIdentifier:(NSString *)identifier;
- (void)setRedraw:(BOOL)yn forIdentifier:(NSString *)identifier;

- (double)frameRateForIdentifier:(NSString *)identifier;
- (void)setFrameRate:(double)frameRate forIdentifier:(NSString *)identifier;

- (NSInteger)rectModeForIdentifier:(NSString *)identifier;
- (void)setRectMode:(NSInteger)flag forIdentifier:(NSString *)identifier;

- (NSInteger)ellipseModeForIdentifier:(NSString *)identifier;
- (void)setEllipseMode:(NSInteger)flag forIdentifier:(NSString *)identifier;

@end
