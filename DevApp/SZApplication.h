//
//  SZApplication.h
//  DevApp
//
//  Created by Todd Ditchendorf on 3/19/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDApplication.h"

@interface SZApplication : EDApplication

- (NSGraphicsContext *)graphicsContextForIdentifier:(NSString *)identifer;
- (void)setGraphicsContext:(NSGraphicsContext *)g forIdentifier:(NSString *)identifer;

- (NSMutableArray *)strokeWeightStackForIdentifier:(NSString *)identifer;
- (void)setStrokeWeightStack:(NSMutableArray *)stack forIdentifier:(NSString *)identifer;
@end
