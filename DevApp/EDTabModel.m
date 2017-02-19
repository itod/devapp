//
//  EDTabModel.m
//  Editor
//
//  Created by Todd Ditchendorf on 8/27/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDTabModel.h"
#import "EDHistory.h"
#import "EDFileLocation.h"
#import "EDDocument.h"
//#import "NSString+EDAdditions.h"

@implementation EDTabModel {
    BOOL _dying;
}

+ (EDTabModel *)lastModified:(EDTabModel *)tm1, ... {
    EDTabModel *result = tm1;
    
    if (tm1) {
        
        va_list vargs;
        va_start(vargs, tm1);
        
        EDTabModel *tm2 = nil;
        while ((tm2 = va_arg(vargs, EDTabModel *))) {
            if (tm2.lastModified > result.lastModified) {
                result = tm2;
            }
        }
        
        va_end(vargs);
    }

    return result;
}


//- (id)init {
//    EDAssert(0);
//    self = [super init];
//    if (self) {
//    }
//    return self;
//}
//
//
//- (instancetype)initWithURLString:(NSString *)URLString type:(NSString *)type {
//    self = [super initWithURLString:URLString type:type];
//    if (self) {
//
//    }
//    return self;
//}


- (void)dealloc {
    _dying = YES;
    self.history = nil;
    [super dealloc];
}


+ (instancetype)fromPlist:(NSDictionary *)plist {
    return [[[self alloc] initFromPlist:plist] autorelease];
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        self.URLString = plist[@"URLString"];
        self.type = plist[@"type"];
        self.title = plist[@"title"];
        self.index = [plist[@"index"] unsignedIntegerValue];
        self.selected = [plist[@"selected"] boolValue];
        
        EDFileLocation *fileLoc = [EDFileLocation fromPlist:plist[@"fileLocation"]];
        EDAssert([fileLoc isKindOfClass:[EDFileLocation class]]);
        
        if ([self.URLString isEqualToString:fileLoc.URLString]) {
            EDAssert([self.URLString isEqualToString:fileLoc.URLString]);
            EDAssert(_history);
            [_history clear];
            [_history insert:fileLoc];
        }
    }
    return self;
}


- (NSDictionary *)asPlist {
    EDAssert(self.URLString);
    EDAssert(self.type);
    EDAssert(self.title);
    
    id d = @{@"URLString": self.URLString,
             @"type": self.type,
             @"title": self.title,
             @"index": @(self.index),
             @"selected": @(self.selected),
             };
    
    id fileLoc = [_history current];
    if ([fileLoc isKindOfClass:[EDFileLocation class]]) {
        EDAssert([self.URLString isEqualToString:[fileLoc URLString]]);

        d = [[d mutableCopy] autorelease];
        d[@"fileLocation"] = [fileLoc asPlist];
    }
    
    //NSLog(@"%@", d);
    return d;
}


- (void)modified {
    self.lastModified = [NSDate timeIntervalSinceReferenceDate];
}


- (BOOL)isMoreRecentlyModifiedThan:(EDTabModel *)tm {
    if (!tm) return YES;
    
    return _lastModified > tm->_lastModified;
}


- (void)setURLString:(NSString *)URLString {
    [self setURLString:URLString storeInHistory:YES];
}


- (void)setURLString:(NSString *)URLString storeInHistory:(BOOL)store {
    EDAssertMainThread();

    // woops, we don't distinguish between headers and Py scripts yet
    // scripts should have relative path.
    //EDAssert(!URLString || ![self.type isEqualToString:EDTabModelTypeSourceCodeFile] || ![URLString isAbsolutePath]);
    
    // woops, typing in the location field can make this fail
    // web locs should have absolute file path or a url string with a scheme
    //EDAssert(!URLString || ![self.type isEqualToString:EDTabModelTypeWebLocation] || ([URLString isAbsolutePath] || [URLString hasSupportedSchemePrefix]));
    
    [super setURLString:URLString];
    
    if (store && !_dying) {
        if (!_history) {
            self.history = [[[EDHistory alloc] init] autorelease];
        }
        EDAssert(_history);
        
        EDFileLocation *fileLoc = [EDFileLocation fileLocationWithURLString:URLString];
        [_history insert:fileLoc];
    }
}

@end
