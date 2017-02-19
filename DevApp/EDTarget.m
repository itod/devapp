//
//  EDTarget.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDTarget.h"
#import "EDScheme.h"

@implementation EDTarget

- (id)init {
    self = [super init];
    if (self) {
        self.name = NSLocalizedString(@"Default", @"");
        self.scheme = [[[EDScheme alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.name = nil;
    self.scheme = nil;
    [super dealloc];
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        self.name = plist[@"name"];
        self.scheme = [EDScheme fromPlist:plist[@"scheme"]];
    }
    return self;
}


- (NSDictionary *)asPlist {
    EDAssert(_name);
    EDAssert(_scheme);
    return @{@"name": _name,
             @"scheme": [_scheme asPlist]
             };
}


//- (id)initWithCoder:(NSCoder *)coder {
//    self.name = [coder decodeObjectForKey:@"name"];
//    self.scheme = [coder decodeObjectForKey:@"scheme"];
//    return self;
//}
//
//
//- (void)encodeWithCoder:(NSCoder *)coder {
//    [coder encodeObject:_name forKey:@"name"];
//    [coder encodeObject:_scheme forKey:@"scheme"];
//}

@end
