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

typedef NS_ENUM(NSInteger, TDRectCorner) {
    TDRectCornerNone = -1,
    
    TDRectCornerTopLef = 0,
    TDRectCornerTopMid = 1,
    TDRectCornerTopRit = 2,
    
    TDRectCornerMidLef = 3,
    TDRectCornerMidMid = 4,
    TDRectCornerMidRit = 5,
    
    TDRectCornerBotLef = 6,
    TDRectCornerBotMid = 7,
    TDRectCornerBotRit = 8,
    
    TDRectCornerAdjust = 9,
    TDRectCornerRotation = 10,
    TDRectCornerConnection = 11,
    
    TDRectCornerConnectionOpt0 = 12,
    TDRectCornerConnectionOpt1 = 13,
    TDRectCornerConnectionOpt2 = 14,
    TDRectCornerConnectionOpt3 = 15,
    TDRectCornerConnectionOpt4 = 16,
};

NSString *TDRectCornerGetDescription(TDRectCorner c);
NSString *TDRectCornerGetDisplayName(TDRectCorner inCorner);

CGPoint TDRectGetMidMidPoint(CGRect r);
CGPoint TDRectGetTopLefPoint(CGRect r);
CGPoint TDRectGetTopMidPoint(CGRect r);
CGPoint TDRectGetTopRitPoint(CGRect r);
CGPoint TDRectGetMidLefPoint(CGRect r);
CGPoint TDRectGetMidRitPoint(CGRect r);
CGPoint TDRectGetBotLefPoint(CGRect r);
CGPoint TDRectGetBotMidPoint(CGRect r);
CGPoint TDRectGetBotRitPoint(CGRect r);

CGPoint TDRectGetCornerPoint(CGRect r, TDRectCorner corner);
CGRect TDCombineRects(CGRect r1, CGRect r2);

@interface SZDocument : EDDocument

@property (nonatomic, retain) NSData *printInfoData;
@property (nonatomic, assign, readonly) CGFloat zoomScale;

@property (nonatomic, retain) NSMutableArray *userGuides;
@property (nonatomic, retain) EDMetrics *metrics;

@property (nonatomic, assign) NSInteger zoomScaleIndex;

@property (nonatomic, assign, getter=isGridEnabled) BOOL gridEnabled;
@property (nonatomic, assign) NSInteger gridTolerance;

@property (nonatomic, assign) NSInteger rulerOriginCorner;

// printing
- (void)doPrint;
@property (nonatomic, retain) EDCanvasPrintView *printView;

// export
@property (nonatomic, assign) EDExportType exportType;
@property (nonatomic, assign) BOOL exportAlphaEnabled;
@property (nonatomic, assign) NSTIFFCompression exportCompressionMethod;
@property (nonatomic, assign) float exportCompressionFactor;
@end
