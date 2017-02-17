//
//  Document.h
//  DevApp
//
//  Created by Todd Ditchendorf on 23.01.17.
//  Copyright © 2017 Celestial Teapot. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WindowController;

@interface Document : NSDocument

@property (nonatomic, retain) WindowController *windowController;
@end

