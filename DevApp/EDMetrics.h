//
//  EDCompositionMetrics.h
//  Editor
//
//  Created by Todd Ditchendorf on 11/29/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDModel.h"

typedef NS_OPTIONS(NSUInteger, EDMetricsUnitType) {
    EDMetricsUnitTypePixels,
    EDMetricsUnitTypeInches,
    EDMetricsUnitTypeCentemeters,
};

@interface EDMetrics : EDModel <NSCopying>

+ (EDMetrics *)defaultMetrics;
+ (EDMetrics *)metricsFromPlist:(NSDictionary *)plist;

+ (NSString *)displayStringForUnitType:(EDMetricsUnitType)t;

- (NSString *)displayString;

- (BOOL)isCustom;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) EDMetricsUnitType unitType;
@property (nonatomic, assign) NSInteger group;
@end
