//
//  EDMemoryCodeRunner.h
//  DevApp
//
//  Created by Todd Ditchendorf on 2/20/17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import "EDCodeRunner.h"
#import <Language/XPInterpreter.h>

@interface EDMemoryCodeRunner : NSObject <EDCodeRunner, XPInterpreterDelegate, XPInterpreterDebugDelegate, NSStreamDelegate>

@end
