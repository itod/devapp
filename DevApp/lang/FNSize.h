//
//  FNSize.h
//  Language
//
//  Created by Todd Ditchendorf on 2/14/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "FNAbstractFunction.h"

@interface FNSize : FNAbstractFunction
+ (void)setupCanvasWithSize:(CGSize)size globals:(XPMemorySpace *)globals;
@end
