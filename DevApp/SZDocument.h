//
//  SZDocument.h
//  Editor
//
//  Created by Todd Ditchendorf on 11/2/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDDocument.h"

@class EDMetrics;
@class EDCanvasPrintView;

typedef NS_OPTIONS(NSUInteger, EDExportType) {
    EDExportTypeTIFF = 0,
    EDExportTypePNG,
    EDExportTypeJPEG,
    EDExportTypePDF,
    EDExportTypeGIF,
};

@interface SZDocument : EDDocument

@property (nonatomic, retain) NSData *printInfoData;
@property (nonatomic, assign, readonly) CGFloat zoomScale;

@property (nonatomic, retain) NSMutableArray *userGuides;
@property (nonatomic, retain) EDMetrics *metrics;

@property (nonatomic, assign) NSInteger zoomScaleIndex;

@property (nonatomic, assign, getter=isGridEnabled) BOOL gridEnabled;
@property (nonatomic, assign) NSInteger gridTolerance;

// printing
- (void)doPrint;
@property (nonatomic, retain) EDCanvasPrintView *printView;

// export
@property (nonatomic, assign) EDExportType exportType;
@property (nonatomic, assign) BOOL exportAlphaEnabled;
@property (nonatomic, assign) NSTIFFCompression exportCompressionMethod;
@property (nonatomic, assign) float exportCompressionFactor;
@end
