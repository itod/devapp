//
//  SZMainWindowController.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/2/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "SZMainWindowController.h"
#import "SZDocument.h"
#import "EDApplication.h"
#import "EDDocumentController.h"
#import "EDMetrics.h"
#import "EDTabModel.h"
#import "EDFileLocation.h"
#import "EDCanvasViewController.h"
#import <IDEKit/IDEUberView.h>
#import <TDAppKit/TDTabBarController.h>
#import <OkudaKit/OKTrigger.h>

#define TIFF_EXT @"tiff"
#define TIF_EXT @"tif"
#define PNG_EXT @"png"
#define JPEG_EXT @"jpeg"
#define JPG_EXT @"jpg"
#define PDF_EXT @"pdf"
#define GIF_EXT @"gif"

#define CANVAS_MARGIN 120.0

@interface SZMainWindowController ()
@end

@implementation SZMainWindowController

- (void)dealloc {
    self.savePanel = nil;
    self.exportAccessoryView = nil;
    self.exportTabView = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark EDMainWindowController

- (NSString *)documentationHomeURLString {
    NSString *URLString = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    return URLString;
}


- (void)setUpCanvasView {
    EDAssert(self.outerUberView);
    
    self.canvasViewController = [[[EDCanvasViewController alloc] init] autorelease];
    self.outerUberView.rightTopView = [self.canvasViewController view];
    self.outerUberView.maxRightSplitWidth = MAXFLOAT;
    
    [self updateCanvasPreferredSplitWidth];
    
    self.canvasViewController.document = [self document];
    
    if ([[EDUserDefaults instance] canvasViewVisible]) {
        [self.outerUberView openRightTopView:nil];
    }
}


- (void)updateCanvasPreferredSplitWidth {
    EDAssertMainThread();
    EDMetrics *metrics = [[self document] metrics];
    EDAssert(metrics);
    
    CGFloat width = [metrics width];
    
    EDAssert(self.outerUberView);
    self.outerUberView.preferredRightSplitWidth = width + CANVAS_MARGIN;
}


- (CGSize)canvasSize {
    EDMetrics *m = [[self document] metrics];
    
    return CGSizeMake(m.width, m.height);
}


- (NSImage *)imageFromData:(NSData *)data {
#if XFER_RAW_DATA
    CGSize size = [self canvasSize];
    NSInteger w = size.width;
    NSInteger h = size.height;
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef cgImg = CGImageCreate(w, h, 8, 32, (4.0 * w), space, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst, provider, NULL, true, kCGRenderingIntentPerceptual);
    
    CGColorSpaceRelease(space);
    CGDataProviderRelease(provider);
#else
    CGImageSourceRef imgSrc = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    CGImageRef cgImg = CGImageSourceCreateImageAtIndex(imgSrc, 0, NULL);
    CFRelease(imgSrc);
    
    CGSize size = CGSizeMake(CGImageGetWidth(cgImg), CGImageGetHeight(cgImg));
#endif
    NSImage *img = [[[NSImage alloc] initWithCGImage:cgImg size:size] autorelease];
    CGImageRelease(cgImg);
    
    return img;
}


#pragma mark -
#pragma mark Actions

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    BOOL enabled = YES;
    
    SEL action = [item action];
    
    if (@selector(toggleGridEnabled:) == action) {
        SZDocument *doc = [self document];
        [item setState:doc.isGridEnabled ? NSOnState : NSOffState];
    } else if (@selector(changeGridTolerance:) == action) {
        SZDocument *doc = [self document];
        [item setState:doc.gridTolerance == [item tag] ? NSOnState : NSOffState];
    } else {
        enabled = [super validateMenuItem:item];
    }

    return enabled;
}


- (IBAction)toggleGridEnabled:(id)sender {
    // using bindings instead
    //    SZDocument *doc = [self document];
    //    EDAssert(doc);
    //    doc.gridEnabled = !doc.isGridEnabled;
    //    [sender setState:[[EDUserDefaults instance] isGridEnabled] ? NSOnState : NSOffState];
}


- (IBAction)changeGridTolerance:(id)sender {
    NSInteger tag = [sender tag];
    SZDocument *doc = [self document];
    EDAssert(doc);
    [doc setGridTolerance:tag];
}


- (IBAction)changeZoomScale:(id)sender {
    SZDocument *doc = [self document];
    EDAssert(doc);
    NSInteger idx = doc.zoomScaleIndex;
    
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        idx = [sender tag];
    }
    
    doc.zoomScaleIndex = idx;
}


- (IBAction)zoomCanvasToActualSize:(id)sender {
    SZDocument *doc = [self document];
    EDAssert(doc);
    doc.zoomScaleIndex = 0;
    [self changeZoomScale:sender];
}


#define MIN_ZOOM_SCALE_INDEX -3
#define MAX_ZOOM_SCALE_INDEX 7

- (IBAction)zoomCanvasIn:(id)sender {
    SZDocument *doc = [self document];
    EDAssert(doc);
    
    if (doc.zoomScaleIndex >= MAX_ZOOM_SCALE_INDEX) {
        NSBeep();
        return;
    }
    doc.zoomScaleIndex++;
    [self changeZoomScale:nil];
}


- (IBAction)zoomCanvasOut:(id)sender {
    SZDocument *doc = [self document];
    EDAssert(doc);
    
    if (doc.zoomScaleIndex <= MIN_ZOOM_SCALE_INDEX) {
        NSBeep();
        return;
    }
    doc.zoomScaleIndex--;
    [self changeZoomScale:nil];
}


#pragma mark -
#pragma mark Export

- (void)enableTermination {
    [[NSProcessInfo processInfo] enableAutomaticTermination:@"saving"];
    [[NSProcessInfo processInfo] enableSuddenTermination];
}


- (void)disableTermination {
    [[NSProcessInfo processInfo] disableAutomaticTermination:@"saving"];
    [[NSProcessInfo processInfo] disableSuddenTermination];
}


- (void)exportTypeDidChange {
    EDAssert(_savePanel);
    [_savePanel setAllowedFileTypes:[NSArray arrayWithObject:[self pathExtensionForExportType]]];
    [_savePanel setAllowsOtherFileTypes:NO];
}


- (EDCanvasView *)canvas {
    return self.canvasViewController.canvasView;
}


- (IBAction)export:(id)sender {
    EDAssertMainThread();
#ifndef APPSTORE
    if (![[EDDocumentController instance] isLicensed]) {
        [[EDDocumentController instance] runNagDialog];
        return;
    }
#endif
    
    self.exporting = YES;
    [self run:nil];
}


- (IBAction)print:(id)sender {
    EDAssertMainThread();
#ifndef APPSTORE
    if (![[EDDocumentController instance] isLicensed]) {
        [[EDDocumentController instance] runNagDialog];
        return;
    }
#endif
    
    self.printing = YES;
    [self run:nil];
}


- (void)doPrint {
    EDAssertMainThread();
    EDAssert(self.printing);
    self.printing = NO;
    
    [[self document] doPrint];
}


- (void)doExport {
    EDAssertMainThread();
    EDAssert(self.exporting);
    self.exporting = NO;
    
    [self disableTermination];
    
    EDUserDefaults *ud = [EDUserDefaults instance];
    SZDocument *doc = [self document];
    EDAssert(doc);
    
    self.savePanel = [NSSavePanel savePanel];
    [_savePanel setCanCreateDirectories:YES];
    [_savePanel setCanSelectHiddenExtension:YES];
    [_savePanel setAllowedFileTypes:[NSArray arrayWithObject:[self pathExtensionForExportType]]];
    [_savePanel setAllowsOtherFileTypes:NO];
    
    [_savePanel setCanSelectHiddenExtension:NO];
    [_savePanel setExtensionHidden:NO];
    [_savePanel setNameFieldLabel:NSLocalizedString(@"Export As:", @"")];
    [_savePanel setNameFieldStringValue:[[doc displayName] stringByDeletingPathExtension]];
    
    //[_savePanel setMessage:[NSString stringWithFormat:NSLocalizedString(@"Export %@ As…", @""), [doc displayName]]];
    
    doc.exportAlphaEnabled = [ud exportAlphaEnabled];
    doc.exportType = [ud exportType];
    
    [_savePanel setAccessoryView:self.exportAccessoryView];
    
    [_savePanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger returnCode) {
        [self exportPanelDidEnd:_savePanel returnCode:returnCode contextInfo:NULL];
        [[self canvas] updateForZoomScale];
    }];
}


- (void)exportPanelDidEnd:(NSSavePanel *)panel returnCode:(NSInteger)code contextInfo:(void *)ctx {
    @try {
        
        EDUserDefaults *ud = [EDUserDefaults instance];
        SZDocument *doc = [self document];
        EDAssert(doc);
        
        [ud setExportAlphaEnabled:doc.exportAlphaEnabled];
        [ud setExportType:doc.exportType];
        
        if (NSFileHandlingPanelCancelButton == code) {
            return;
        }
        
        NSString *s = [[[[_savePanel URL] relativePath] stringByStandardizingPath] stringByExpandingTildeInPath];
        if (![self hasSupportedPathExtension:s]) {
            s = [[s stringByDeletingPathExtension] stringByAppendingPathExtension:[self pathExtensionForExportType]];
        }
        
        EDCanvasView *canvas = [self canvas];
        
        NSData *data = nil;
        NSImage *image = canvas.image;
        
        switch (doc.exportType) {
            case EDExportTypeTIFF: {
                //            NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:
                //                                   [NSNumber numberWithInteger:_exportCompressionMethod], NSImageCompressionMethod,// TIFF input/output (NSTIFFCompression in NSNumber)
                //                                   [NSNumber numberWithFloat:exportCompressionFactor], NSImageCompressionFactor, // TIFF/JPEG input/output (float in NSNumber)
                //                                   //[imgRep setProperty:NSImageColorSyncProfileData withValue:nil]; // TIFF,GIF input/output (NSData)
                //                                   nil];
                
                //data = [[NSBitmapImageRep imageRepWithData:data] representationUsingType:NSTIFFFileType properties:props];
                data = [image TIFFRepresentationUsingCompression:doc.exportCompressionMethod factor:doc.exportCompressionFactor];
            } break;
                
            case EDExportTypePNG: {
                //[imgRep setProperty:NSImageInterlaced withValue:nil]; // PNG output (BOOL in NSNumber)
                //[imgRep setProperty:NSImageGamma withValue:nil]; // PNG input/output (float in NSNumber)
                
                data = [[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]] representationUsingType:NSPNGFileType properties:@{}];
            } break;
                
            case EDExportTypeJPEG: {
                NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithFloat:doc.exportCompressionFactor], NSImageCompressionFactor, // TIFF/JPEG input/output (float in NSNumber)
                                       //[imgRep setProperty:NSImageProgressive withValue:nil]; // JPEG input/output (BOOL in NSNumber)
                                       //[imgRep setProperty:NSImageEXIFData withValue:nil]; // JPEG input/output (NSDictionary)
                                       //[imgRep setProperty:NSImageFallbackBackgroundColor withValue:nil]; // JPEG output (NSColor)
                                       nil];
                data = [[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:props];
            } break;
                
            case EDExportTypePDF: {
                data = [self PDFDataForImage:image];
            } break;
                
            case EDExportTypeGIF: {
                //            [imgRep setProperty:NSImageDitherTransparency withValue:nil]; // GIF output (BOOL in NSNumber)
                //            [imgRep setProperty:NSImageRGBColorTable withValue:nil]; // GIF input/output (packed RGB in NSData)
                //
                //            [imgRep setProperty:NSImageColorSyncProfileData withValue:nil]; // TIFF,GIF input/output (NSData)
                //            [imgRep setProperty:NSImageFrameCount withValue:nil]; // GIF input (int in NSNumber) (read-only)
                //            [imgRep setProperty:NSImageCurrentFrame withValue:nil]; // GIF input (int in NSNumber)
                //            [imgRep setProperty:NSImageCurrentFrameDuration withValue:nil]; // GIF input (float in NSNumber) (read-only)
                //            [imgRep setProperty:NSImageLoopCount withValue:nil]; // GIF input (int in NSNumber) (read-only)
                
                data = [[NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]] representationUsingType:NSGIFFileType properties:@{}];
            } break;
                
            default:
                NSAssert(@"unknown exportType", @"");
                break;
        }
        
        NSError *err = nil;
        if (![data writeToFile:s options:NSDataWritingAtomic error:&err]) {
            if (err) {
                NSLog(@"%@", err);
                NSString *title = NSLocalizedString(@"Could not export image", @"");
                NSString *msg = [err localizedDescription];
                NSString *defaultBtn = NSLocalizedString(@"OK", @"");
                NSString *altBtn = nil;
                NSString *otherBtn = nil;
                NSRunAlertPanel(title, @"%@", defaultBtn, altBtn, otherBtn, msg);
            }
        }
        
        self.savePanel = nil;
    }
    @finally {
        [self enableTermination];
    }
}


- (NSData *)PDFDataForImage:(NSImage *)image {
    NSMutableData *data = [NSMutableData data];
    CGDataConsumerRef consumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)data);
    if (!consumer) {
        NSLog(@"could not create consumer");
        return nil;
    }
    
    CGSize imgSize = [image size];
    
    CGRect mediaBox = CGRectMake(0.0, 0.0, imgSize.width, imgSize.height);
    
    CGContextRef ctx = CGPDFContextCreate(consumer, &mediaBox, NULL);
    CFRelease(consumer);
    
    NSGraphicsContext *oldGc = [NSGraphicsContext currentContext];
    NSGraphicsContext *pdfGc = [NSGraphicsContext graphicsContextWithGraphicsPort:ctx flipped:NO];
    [NSGraphicsContext setCurrentContext:pdfGc];
    
    CGPDFContextBeginPage(ctx, NULL);
    CGContextSaveGState(ctx);
    
    id hints = @{NSImageHintInterpolation: @(NSImageInterpolationHigh)};
    
    [image drawInRect:mediaBox fromRect:mediaBox operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:hints];
    
    [NSGraphicsContext setCurrentContext:oldGc];
    CGContextRestoreGState(ctx);
    CGPDFContextEndPage(ctx);
    
    CGPDFContextClose(ctx);
    CGContextRelease(ctx);
    
    return data;
}


- (NSString *)pathExtensionForExportType {
    SZDocument *doc = [self document];
    NSString *ext = nil;
    switch (doc.exportType) {
        case EDExportTypeTIFF:
            ext = TIFF_EXT;
            break;
        case EDExportTypePNG:
            ext = PNG_EXT;
            break;
        case EDExportTypeJPEG:
            ext = JPG_EXT;
            break;
        case EDExportTypePDF:
            ext = PDF_EXT;
            break;
        case EDExportTypeGIF:
            ext = GIF_EXT;
            break;
        default:
            NSAssert(0, @"unknown export type");
            break;
    }
    
    return ext;
}


- (NSArray *)allowedPathExtensions {
    static NSArray *sExts = nil;
    if (!sExts) {
        //        sExts = [[NSArray alloc] initWithObjects:@"png", @"tiff", @"tif", @"jpeg", @"jpg", @"gif", nil];
        sExts = [[NSArray alloc] initWithObjects:TIFF_EXT, TIF_EXT, PNG_EXT, JPEG_EXT, JPG_EXT, PDF_EXT, GIF_EXT, nil];
    }
    return sExts;
}


- (BOOL)hasSupportedPathExtension:(NSString *)s {
    NSString *ext = [[s pathExtension] lowercaseString];
    if (![ext length]) return NO;
    
    return [[self allowedPathExtensions] containsObject:ext];
}

@end
