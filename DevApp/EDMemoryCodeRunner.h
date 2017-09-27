//
//  EDMemoryCodeRunner.h
//  DevApp
//
//  Created by Todd Ditchendorf on 2/20/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDBaseCodeRunner.h"
#import <Language/XPInterpreter.h>

@interface EDMemoryCodeRunner : EDBaseCodeRunner <XPInterpreterDelegate, XPInterpreterDebugDelegate, NSStreamDelegate>

@end
