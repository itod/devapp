//
//  EDFilesystemItem.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/21/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDFilesystemItem.h"
#import "EDPattern.h"

static EDFilesystemItem *sRootItem = nil;
static NSMutableArray *sLeafNode = nil;
static NSMutableDictionary *sCache = nil;

@interface EDFilesystemItem ()
- (id)initWithFullPath:(NSString *)path;

@property (nonatomic, copy, readwrite) NSString *fullPath;
@property (nonatomic, copy, readwrite) NSString *relativePath;
@property (nonatomic, retain, readwrite) NSMutableArray *children;
@property (nonatomic, retain, readwrite) NSImage *icon;
@end

@implementation EDFilesystemItem

+ (void)initialize {
    if ([EDFilesystemItem class] == self) {
        sLeafNode = [[NSMutableArray alloc] init];
        [self clearCache];
    }
}


+ (NSString *)pasteboardType {
    return NSStringFromClass(self);
}


+ (EDFilesystemItem *)rootItem {
    EDAssert(0);
    if (sRootItem == nil) {
        sRootItem = [[EDFilesystemItem itemWithFullPath:@"/"] retain];
    }
    return sRootItem;
}


+ (void)clearCache {
//    [sRootItem autorelease];
//    sRootItem = nil;
    
    [sCache autorelease];
    sCache = [[NSMutableDictionary alloc] init];
}


+ (EDFilesystemItem *)itemWithFullPath:(NSString *)fullPath {

    EDFilesystemItem *item = nil;

    BOOL wantsCache = ![fullPath hasPrefix:EDProjectSettingsURL];
    if (wantsCache) {
        item = [sCache objectForKey:fullPath];
    }
    
    if (!item) {
        item = [[[EDFilesystemItem alloc] initWithFullPath:fullPath] autorelease];
        if (wantsCache) {
            [sCache setObject:item forKey:fullPath];
        }
    }
    
    return item;
}


- (id)initWithFullPath:(NSString *)fullPath {
    self = [super init];
    if (self) {
        // unforunately, this is required, or the NSString methods below change exedore:// to exedore:/
        if ([fullPath isEqualToString:EDProjectSettingsURL]) {
            self.fullPath = fullPath;
            self.relativePath = fullPath;
        } else {
            self.fullPath = [fullPath stringByExpandingTildeInPath];
            self.relativePath = [fullPath lastPathComponent];
        }
        EDAssert([_fullPath length]);
        EDAssert([_relativePath length]);
    }
    return self;
}


- (void)dealloc {
    self.fullPath = nil;
    self.relativePath = nil;
    self.children = nil;
    self.icon = nil;
    [super dealloc];
}


- (id)initWithCoder:(NSCoder *)coder {
    self.fullPath = [coder decodeObjectForKey:@"fullPath"];
    EDAssert(_fullPath);
    
    self.relativePath = [_fullPath lastPathComponent];
//    self.children = [coder decodeObjectForKey:@"children"];
    
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_fullPath forKey:@"fullPath"];
//    [coder encodeObject:_children forKey:@"children"];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p %@>", [self class], self, _fullPath];
}


- (BOOL)isEqual:(id)obj {
    if (![obj isKindOfClass:[EDFilesystemItem class]]) {
        return NO;
    }
    
    EDFilesystemItem *fsItem = (EDFilesystemItem *)obj;
    return [self.fullPath isEqualToString:fsItem.fullPath];
}


- (void)reloadChildren {
    for (EDFilesystemItem *child in _children) {
        [child reloadChildren];
    }
    
    self.children = nil;
}


- (BOOL)shouldExclude:(NSString *)filename {
    BOOL exclude = NO;
    
    NSArray *pats = [[EDUserDefaults instance] excludeFilePatterns];
    for (EDPattern *pat in pats) {
        if ([pat isMatch:filename]) {
            exclude = YES;
            break;
        }
    }
    
    return exclude;
}


// Creates, caches, and returns the array of children
// Loads children incrementally
- (NSArray *)children {
    EDAssert([_fullPath length]);
    
    if (!_children) {
        NSFileManager *mgr = [NSFileManager defaultManager];

        BOOL isDir;
        if ([mgr fileExistsAtPath:_fullPath isDirectory:&isDir] && isDir) {
            NSArray *filenames = [mgr contentsOfDirectoryAtPath:_fullPath error:nil];

            NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[filenames count]];
            
            for (NSString *filename in filenames) {
                if ([filename hasPrefix:@"."] || [self shouldExclude:filename]) continue;
                
                NSString *childPath = [_fullPath stringByAppendingPathComponent:filename];
                EDFilesystemItem *newChild = [EDFilesystemItem itemWithFullPath:childPath];
                [arr addObject:newChild];
            }
            
            self.children = arr;
        } else {
            self.children = sLeafNode;
        }
    }
    
    EDAssert(_children);
    return _children;
}


- (EDFilesystemItem *)childAtIndex:(NSUInteger)n {
    return [self.children objectAtIndex:n];
}


- (EDFilesystemItem *)descendantAtFullPath:(NSString *)targetPath {
    EDFilesystemItem *target = nil;
    
    if ([targetPath hasPrefix:_fullPath]) {
        if ([targetPath isEqualToString:_fullPath]) return self;
        
        NSUInteger len = [_fullPath length];
        NSString *childName = [[targetPath substringFromIndex:len] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        NSArray *comps = [childName componentsSeparatedByString:@"/"];
        childName = [comps objectAtIndex:0];
        
        for (EDFilesystemItem *child in self.children) {
            if ([child.relativePath isEqualToString:childName]) {
                return [child descendantAtFullPath:targetPath];
                break;
            }
        }
        
    }
    
    return target;
}


- (BOOL)isLeaf {
    // must go thru getter here
    BOOL result = self.children == sLeafNode;
    return result;
}


- (NSInteger)numberOfChildren {
    NSInteger c = self.isLeaf ? (-1) : [self.children count];
    return c;
}

@end