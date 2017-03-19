//
//  FNAbstractFunction.h
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "XPFunctionBody.h"

@interface FNAbstractFunction : XPFunctionBody
- (void)postUpate;

@property (nonatomic, retain) NSGraphicsContext *canvasGraphicsContext;
@end
