//
//  EDCompositionMetrics.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/29/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDMetrics.h"
#import "EDUserDefaults.h"

#define DEFAULT_IDX 1 // 300x300

@implementation EDMetrics

+ (EDMetrics *)defaultMetrics {
    EDMetrics *m = [[EDUserDefaults instance] lastSelectedMetrics];
    if (!m) {
        NSArray *infos = [[EDUserDefaults instance] presetMetricsInfos];
        m = [EDMetrics metricsFromPlist:[infos objectAtIndex:DEFAULT_IDX]];
    }
    return m;
}


+ (EDMetrics *)metricsFromPlist:(NSDictionary *)plist {
    EDMetrics *m = [[[EDMetrics alloc] init] autorelease];
    m.name = [plist objectForKey:@"name"];
    m.width = [[plist objectForKey:@"width"] doubleValue];
    m.height = [[plist objectForKey:@"height"] doubleValue];
    m.unitType = [[plist objectForKey:@"unitType"] integerValue];
    m.group = [[plist objectForKey:@"group"] integerValue];
    return m;
}


+ (NSString *)displayStringForUnitType:(EDMetricsUnitType)t {
    NSString * s = nil;
    
    switch (t) {
        case EDMetricsUnitTypePixels:
            s = NSLocalizedString(@"pixels", @"");
            break;
        case EDMetricsUnitTypeInches:
            s = NSLocalizedString(@"inches", @"");
            break;
        case EDMetricsUnitTypeCentemeters:
            s = NSLocalizedString(@"cm", @"");
            break;
        default:
            NSAssert(0, @"unknown unitType");
            break;
    }
    
    return s;
}


- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}


- (void)dealloc {
    self.name = nil;
    [super dealloc];
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        self.name = plist[@"name"];
        self.width = [plist[@"width"] doubleValue];
        self.height = [plist[@"height"] doubleValue];
        self.unitType = [plist[@"unitType"] unsignedIntegerValue];
        self.group = [plist[@"group"] integerValue];
    }
    return self;
}


- (NSDictionary *)asPlist {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              @(_width), @"width",
                              @(_height), @"height",
                              @(_unitType), @"unitType",
                              @(_group), @"group",
                              nil];
    
    if (_name) {
        [d setObject:_name forKey:@"name"];
    }
    
    return [[d copy] autorelease];
}

//- (id)initWithCoder:(NSCoder *)coder {
//    self.name = [coder decodeObjectForKey:@"name"];
//    self.width = [coder decodeDoubleForKey:@"width"];
//    self.height = [coder decodeDoubleForKey:@"height"];
//    self.unitType = [coder decodeIntegerForKey:@"unitType"];
//    self.group = [coder decodeIntegerForKey:@"group"];
//    return self;
//}
//
//
//- (void)encodeWithCoder:(NSCoder *)coder {
//    [coder encodeObject:_name forKey:@"name"];
//    [coder encodeDouble:_width forKey:@"width"];
//    [coder encodeDouble:_height forKey:@"height"];
//    [coder encodeInteger:_unitType forKey:@"unitType"];
//    [coder encodeInteger:_group forKey:@"group"];
//}


- (id)copyWithZone:(NSZone *)zone {
    EDMetrics *m = [[[self class] allocWithZone:zone] init];
    m->_name = [_name copy];
    m->_width = _width;
    m->_height = _height;
    m->_unitType = _unitType;
    m->_group = _group;
    return m;
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p {%.0f, %.0f} %@>", [self class], self, _width, _height, [[self class] displayStringForUnitType:_unitType]];
}


- (BOOL)isEqual:(id)that {
    if (![that isMemberOfClass:[self class]]) {
        return NO;
    }
    
    EDMetrics *m = (EDMetrics *)that;
    
    // be careful. be sure to check for nil first if your are going to compare names
    //if (![_name isEqualToString:m->_name]) return NO;
    if (m->_width != _width) return NO;
    if (m->_height != _height) return NO;
    if (m->_unitType != _unitType) return NO;
    if (m->_group != _group) return NO;
    
    return YES;
}


- (NSString *)displayString {
    if ([self isCustom]) {
        return [NSString stringWithFormat:@"%0.f x %0.f", _width, _height];
    } else if ([_name length]) {
        return NSLocalizedString(_name, @"");
    } else {
        return [NSString stringWithFormat:@"%0.f x %0.f", _width, _height];
    }
}


- (BOOL)isCustom {
    return [_name isEqualToString:NSLocalizedString(@"Custom", @"")];
}

@end
