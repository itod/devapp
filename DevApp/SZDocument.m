//
//  SZDocument.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/2/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "SZDocument.h"
#import "EDMetrics.h"
#import "SZMainWindowController.h"
#import "EDCanvasViewController.h"
#import "EDCanvasPrintView.h"
#import "EDGuide.h"
#import "EDTabModel.h"

@interface EDDocument ()
@property (nonatomic, retain) NSMutableArray *tempTabModels;
@end

@interface SZDocument ()
@end

@implementation SZDocument

- (id)init {
    self = [super init];
    if (self) {
        _userGuides = [[NSMutableArray alloc] init];
        _metrics = [[EDMetrics defaultMetrics] retain];
        _zoomScaleIndex = 0;
        
        _gridEnabled = [[EDUserDefaults instance] isGridEnabled];
        _gridTolerance = [[EDUserDefaults instance] gridTolerance];
        
        _exportType = EDExportTypePNG;
        _exportAlphaEnabled = YES;
        _exportCompressionFactor = 0.8f;
        _exportCompressionMethod = NSTIFFCompressionNone;
    }
    return self;
}


- (void)dealloc {
    self.printInfoData = nil;
    self.userGuides = nil;
    self.metrics = nil;
    self.printView = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSDocument


#pragma mark -
#pragma mark EDDocument

- (BOOL)wantsCustomDisplayName {
    return NO;
}


- (BOOL)storeProjPlistOfType:(NSString *)typeName inDict:(NSMutableDictionary *)dict error:(NSError **)outErr {
    BOOL result = [super storeProjPlistOfType:typeName inDict:dict error:outErr];
    
    if (result) {
        EDAssert(_userGuides);
        NSMutableArray *guides = [NSMutableArray arrayWithCapacity:[_userGuides count]];
        for (EDGuide *g in _userGuides) {
            [guides addObject:[g asPlist]];
        }
        dict[@"userGuides"] = guides;
        
        EDAssert(_metrics);
        dict[@"metrics"] = [_metrics asPlist];
        
        dict[@"zoomScaleIndex"] = @(_zoomScaleIndex);
        dict[@"gridEnabled"] = @(_gridEnabled);
        dict[@"gridTolerance"] = @(_gridTolerance);
        
        dict[@"exportType"] = @(_exportType);
        dict[@"exportAlphaEnabled"] = @(_exportAlphaEnabled);
        dict[@"exportCompressionMethod"] = @(_exportCompressionMethod);
        dict[@"exportCompressionFactor"] = @(_exportCompressionFactor);
    }
    
    return result;
}


- (BOOL)readProjPlistOfType:(NSString *)typeName inDict:(NSMutableDictionary *)dict error:(NSError **)outErr {
    //EDAssert(1 == [dict[@"version"] integerValue]);
    
    if ([super readProjPlistOfType:typeName inDict:dict error:outErr]) {
        
        NSArray *guides = dict[@"userGuides"];
        [_userGuides release];
        _userGuides = [[NSMutableArray alloc] initWithCapacity:[guides count]];

        for (NSDictionary *d in guides) {
            EDGuide *g = [EDGuide fromPlist:d];
            [_userGuides addObject:g];
        }
        
        EDMetrics *metrics = [EDMetrics fromPlist:dict[@"metrics"]];
        EDAssert(metrics);
        [_metrics release];
        _metrics = [metrics retain];
        
        _zoomScaleIndex = [dict[@"zoomScaleIndex"] integerValue];
        _gridEnabled = [dict[@"gridEnabled"] boolValue];
        _gridTolerance = [dict[@"gridTolerance"] integerValue];
        
        _exportType = [dict[@"exportType"] unsignedIntegerValue];
        _exportAlphaEnabled = [dict[@"exportAlphaEnabled"] boolValue];
        _exportCompressionMethod = [dict[@"exportCompressionMethod"] integerValue];
        _exportCompressionFactor = [dict[@"exportCompressionFactor"] floatValue];
    }
    
    return YES;
}


#pragma mark -
#pragma mark Helper

- (void)ensureDirExistsAtPath:(NSString *)dirPath {
    EDAssert([dirPath length]);
    
    NSError *err = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];

    BOOL isDir;
    if (![mgr fileExistsAtPath:dirPath isDirectory:&isDir] || !isDir) {
        
        err = nil;
        if (![mgr createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&err]) {
            NSLog(@"Could not create dir at path %@", dirPath);
            if (err) NSLog(@"%@", err);
        }
    }
}


- (CGFloat)zoomScale {
    CGFloat scale = 1.0;
    
    switch (_zoomScaleIndex) {
        case -3:
            scale = 0.25;
            break;
        case -2:
            scale = 0.5;
            break;
        case -1:
            scale = 0.75;
            break;
        case 0:
            scale = 1.0;
            break;
        case 1:
            scale = 1.25;
            break;
        case 2:
            scale = 1.5;
            break;
        case 3:
            scale = 1.75;
            break;
        case 4:
            scale = 2.0;
            break;
        case 5:
            scale = 3.0;
            break;
        case 6:
            scale = 4.0;
            break;
        case 7:
            scale = 5.0;
            break;
        default:
            NSAssert(0, @"unkown zoomScaleIndex");
            break;
    }
    
    return scale;
}


#pragma mark -
#pragma mark Printing

- (IBAction)printDocument:(id)sender {
    EDAssertMainThread();
    [(SZMainWindowController *)self.mainWindowController print:sender];
}


- (void)doPrint {
    EDAssertMainThread();
    EDMainWindowController *wc = self.mainWindowController;
    
    self.printView = [[[EDCanvasPrintView alloc] init] autorelease];
    _printView.metrics = _metrics;
    _printView.canvas = wc.canvasViewController.canvasView;
    
    NSWindow *win = [wc window];
    
    // find existing or create new print info
    NSPrintInfo *info = nil;
    
    if (_printInfoData) {
        NSDictionary *infoDict = [NSKeyedUnarchiver unarchiveObjectWithData:_printInfoData];
        info = [[[NSPrintInfo alloc] initWithDictionary:infoDict] autorelease];
    }
    
    if (!info) {
        info = [self printInfo];
    }
    
    // customize print info
    
    // orientation
    NSPaperOrientation orient = [_printView printingOrientation];
    [info setOrientation:orient];
    
    // centering
    //    [info setLeftMargin:0.0];
    //    [info setRightMargin:0.0];
    //    [info setTopMargin:0.0];
    //    [info setBottomMargin:0.0];
    [info setHorizontallyCentered:YES];
    [info setVerticallyCentered:YES];
    
    [info setHorizontalPagination:NSAutoPagination];
    [info setVerticalPagination:NSAutoPagination];
    
    [_printView prepareWithPrintInfo:info];
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:_printView printInfo:info];
    
    [op runOperationModalForWindow:win delegate:self didRunSelector:@selector(printOperationDidRun:success:contextInfo:) contextInfo:NULL];
}


- (void)printOperationDidRun:(NSPrintOperation *)op success:(BOOL)success contextInfo:(void *)ctx {
    if (success) {
        // store printInfoData
        NSPrintInfo *info = [op printInfo];
        NSData *infoData = [NSKeyedArchiver archivedDataWithRootObject:[info dictionary]];
        self.printInfoData = infoData;
        
        // save here as well, JIC
        [self setPrintInfo:info];
        
        // kill printView
        self.printView = nil;
    }
}


#pragma mark -
#pragma mark Properties

- (void)setUserGuides:(NSMutableArray *)userGuides {
    EDAssertMainThread();
    
    if (userGuides != _userGuides) {
        [self willChangeValueForKey:@"userGuides"];
        
        [_userGuides release];
        _userGuides = [userGuides retain];
        
        [self updateChangeCount:NSChangeDone];
        
        [self didChangeValueForKey:@"userGuides"];
    }
}


- (void)setZoomScaleIndex:(NSInteger)idx {
    EDAssertMainThread();
    
    if (idx != _zoomScaleIndex) {
        [self willChangeValueForKey:@"zoomScaleIndex"];
        
        _zoomScaleIndex = idx;
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:EDCompositionZoomScaleDidChangeNotification object:self];
        
        [self didChangeValueForKey:@"zoomScaleIndex"];
    }
}


- (void)setGridEnabled:(BOOL)yn {
    EDAssertMainThread();
    
    if (yn != _gridEnabled) {
        [self willChangeValueForKey:@"gridEnabled"];
        
        [[self undoManager] beginUndoGrouping];
        
        [[[self undoManager] prepareWithInvocationTarget:self] setGridEnabled:_gridEnabled];
        [[self undoManager] setActionName:NSLocalizedString(@"Set Grid Enabled", @"")];
        
        _gridEnabled = yn;
        
        [[self undoManager] endUndoGrouping];
        
        [self updateChangeCount:NSChangeDone];
        
        [[EDUserDefaults instance] setGridEnabled:_gridEnabled];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:EDCompositionGridEnabledDidChangeNotification object:self];
        
        [self didChangeValueForKey:@"gridEnabled"];
    }
}


- (void)setGridTolerance:(NSInteger)d {
    EDAssertMainThread();
    
    if (d != _gridTolerance) {
        [self willChangeValueForKey:@"gridTolerance"];
        
        [[self undoManager] beginUndoGrouping];
        
        [(SZDocument *)[[self undoManager] prepareWithInvocationTarget:self] setGridTolerance:_gridTolerance];
        [[self undoManager] setActionName:NSLocalizedString(@"Set Grid Snap Tolerance", @"")];
        
        _gridTolerance = d;
        
        [[self undoManager] endUndoGrouping];
        
        [self updateChangeCount:NSChangeDone];
        
        [[EDUserDefaults instance] setGridTolerance:_gridTolerance];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:EDCompositionGridToleranceDidChangeNotification object:self];
        
        [self didChangeValueForKey:@"gridTolerance"];
    }
}


- (void)setExportType:(EDExportType)t {
    EDAssertMainThread();
    
    if (_exportType != t) {
        [self willChangeValueForKey:@"exportType"];
        
        _exportType = t;
        
        [(SZMainWindowController *)[self mainWindowController] exportTypeDidChange];
        
        [self didChangeValueForKey:@"exportType"];
    }
}

@end
