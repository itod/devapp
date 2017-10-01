//
//  EDCanvasViewController.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/26/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDCanvasViewController.h"
#import "SZApplication.h"
#import "EDCanvasView.h"
#import "EDMetrics.h"
#import "EDGuide.h"
#import "SZDocument.h"
#import "EDStatusBar.h"
#import <TDAppKit/TDStatusBarPopUpView.h>
#import <TDAppKit/TDStatusBarButton.h>
#import <TDAppKit/TDViewControllerView.h>
#import <TDAppKit/TDUtils.h>

@interface EDCanvasViewController ()

@end

@implementation EDCanvasViewController

- (id)init {
    self = [self initWithNibName:@"EDCanvasView" bundle:nil];
    return self;
}


- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)b {
    self = [super initWithNibName:name bundle:b];
    if (self) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(compositionMetricsDidChange:) name:EDCompositionMetricsDidChangeNotification object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[self view] removeFromSuperview];

    if (_canvasView) {
        EDAssert(_canvasView.delegate == self);
        _canvasView.delegate = nil;
    }
    self.canvasView = nil;
    self.scrollView = nil;
    
    EDAssert(_zoomPopUpView.popUpButton);
    //NSLog(@"%@", [_zoomPopUpView.popUpButton infoForBinding:@"selectedTag"]);
    [_zoomPopUpView.popUpButton unbind:@"selectedTag"];
    //NSLog(@"%@", [_zoomPopUpView.popUpButton infoForBinding:@"selectedTag"]);

    EDAssert(_gridPopUpView.popUpButton);
    [_gridPopUpView.popUpButton unbind:@"selectedTag"];
    
    EDAssert(_gridPopUpView.checkbox);
    [_gridPopUpView.checkbox unbind:@"value"];
    
    self.zoomPopUpView = nil;
    self.gridPopUpView = nil;
    self.metricsButton = nil;
    
    self.document = nil;
    self.delegate = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark TDViewController

- (void)viewDidLoad {
    EDAssert([[self view] isKindOfClass:[TDViewControllerView class]]);
    EDAssert(_canvasView);
    EDAssert(_scrollView);

    _canvasView.delegate = self;
    
    [self setUpRulerViews];
    
    //[_canvasView performSelector:@selector(updateForZoomScale) withObject:nil afterDelay:0.0];

    EDAssert(_gridPopUpView);
    EDAssert(_zoomPopUpView);
    EDAssert(_metricsButton);
    
    NSGradient *grad = TDVertGradient(0xdddddd, 0x999999);

    _gridPopUpView.labelText = NSLocalizedString(@"            ", @"");
    _zoomPopUpView.labelText = NSLocalizedString(@"Zoom:", @"");
    
    _gridPopUpView.mainTopBorderColor = [EDStatusBar mainTopBorderColor];
    _gridPopUpView.nonMainTopBorderColor = [EDStatusBar nonMainTopBorderColor];
    _gridPopUpView.mainBgGradient = grad;

    _zoomPopUpView.mainTopBorderColor = [EDStatusBar mainTopBorderColor];
    _zoomPopUpView.nonMainTopBorderColor = [EDStatusBar nonMainTopBorderColor];
    _zoomPopUpView.mainBgGradient = grad;
    
    _metricsButton.mainTopBorderColor = [EDStatusBar mainTopBorderColor];
    _metricsButton.nonMainTopBorderColor = [EDStatusBar nonMainTopBorderColor];
    _metricsButton.mainBgGradient = grad;
    
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        EDAssert(_canvasView);
        [_canvasView setFrame:[_canvasView frame]];
        [_canvasView setNeedsDisplay:YES];
        [_canvasView scrollToCenter];
    });
}


#pragma mark -
#pragma mark Public

- (void)update {
    TDAssertMainThread();
    EDAssert(_canvasView);

    NSString *identifier = [[[self.view window] windowController] identifier];
    NSImage *img = [[SZApplication instance] sharedImageForIdentifier:identifier];
    
    _canvasView.image = img;
    //_canvasView.context = ctx;
    [_canvasView setNeedsDisplay:YES];
    
    [self.zoomPopUpView updateValue];
    [self.gridPopUpView updateValue];
}


- (void)clear {
    TDAssertMainThread();
    NSString *identifier = [[[self.view window] windowController] identifier];
    [[SZApplication instance] setSharedImage:nil forIdentifier:identifier];
    
    [self update];
}


#pragma mark -
#pragma mark EDCanvasViewDelegate

- (void)canvas:(EDCanvasView *)canvas didMoveUserGuide:(EDGuide *)g from:(CGPoint)oldPoint to:(CGPoint)newPoint {
    EDAssert(_canvasView);
    NSRulerView *rulerView = nil;
    NSRulerView *vertRulerView = [canvas verticalRulerView];
    NSRulerView *horizRulerView = [canvas horizontalRulerView];

    CGPoint offset = [canvas scaledCompositionFrame].origin;
    CGRect visRect = [canvas visibleRect];
    offset.x -= visRect.origin.x;
    offset.y -= visRect.origin.y;

    CGFloat oldLoc, newLoc;

    if ([g isVertical]) {
        CGFloat ruleThickness = [vertRulerView ruleThickness];
        rulerView = horizRulerView;
        oldLoc = floor(oldPoint.x + offset.x + ruleThickness);
        newLoc = floor(newPoint.x + offset.x + ruleThickness);
    } else {
        BOOL isFlipped = [canvas isFlipped];
        CGFloat ruleThickness = isFlipped ? 0.0 : [horizRulerView ruleThickness];
        rulerView = vertRulerView;
        oldLoc = floor(oldPoint.y + offset.y + ruleThickness);
        newLoc = floor(newPoint.y + offset.y + ruleThickness);
    }
    
    [rulerView moveRulerlineFromLocation:oldLoc toLocation:newLoc];
}


- (void)canvas:(EDCanvasView *)canvas mouseEntered:(NSEvent *)evt {
    TDAssertMainThread();
    [self.delegate canvasViewController:self mouseEvent:evt];
}


- (void)canvas:(EDCanvasView *)canvas mouseExited:(NSEvent *)evt {
    TDAssertMainThread();
    [self.delegate canvasViewController:self mouseEvent:evt];
}


- (void)canvas:(EDCanvasView *)canvas mouseDown:(NSEvent *)evt {
    TDAssertMainThread();
    [self.delegate canvasViewController:self mouseEvent:evt];
}


- (void)canvas:(EDCanvasView *)canvas mouseUp:(NSEvent *)evt {
    TDAssertMainThread();
    [self.delegate canvasViewController:self mouseEvent:evt];
}


- (void)canvas:(EDCanvasView *)canvas mouseMoved:(NSEvent *)evt {
    TDAssertMainThread();
    [self.delegate canvasViewController:self mouseEvent:evt];
}


- (void)canvas:(EDCanvasView *)canvas mouseDragged:(NSEvent *)evt {
    TDAssertMainThread();
    [self.delegate canvasViewController:self mouseEvent:evt];
}


#pragma mark -
#pragma mark Private

- (void)setUpRulerViews {
    EDAssert(_scrollView);
    
    [NSRulerView registerUnitWithName:@"Points-3" abbreviation:@"pts" unitToPointsConversionFactor:0.25 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    [NSRulerView registerUnitWithName:@"Points-2" abbreviation:@"pts" unitToPointsConversionFactor:0.5 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    [NSRulerView registerUnitWithName:@"Points-1" abbreviation:@"pts" unitToPointsConversionFactor:0.75 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    //[NSRulerView registerUnitWithName:@"Points" abbreviation:@"pts" unitToPointsConversionFactor:1.0 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    [NSRulerView registerUnitWithName:@"Points1" abbreviation:@"pts" unitToPointsConversionFactor:1.25 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    [NSRulerView registerUnitWithName:@"Points2" abbreviation:@"pts" unitToPointsConversionFactor:1.5 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    [NSRulerView registerUnitWithName:@"Points3" abbreviation:@"pts" unitToPointsConversionFactor:1.75 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    [NSRulerView registerUnitWithName:@"Points4" abbreviation:@"pts" unitToPointsConversionFactor:2.0 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    [NSRulerView registerUnitWithName:@"Points5" abbreviation:@"pts" unitToPointsConversionFactor:3.0 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    [NSRulerView registerUnitWithName:@"Points6" abbreviation:@"pts" unitToPointsConversionFactor:4.0 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    [NSRulerView registerUnitWithName:@"Points7" abbreviation:@"pts" unitToPointsConversionFactor:5.0 stepUpCycle:@[@10.0] stepDownCycle:@[@0.5]];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(rulersVisibleDidChange:) name:EDRulersVisibleDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(gridVisibleDidChange:) name:EDGridVisibleDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(guidesVisibleDidChange:) name:EDGuidesVisibleDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(compositionZoomScaleDidChange:) name:EDCompositionZoomScaleDidChangeNotification object:nil];
    
    [_scrollView setHasHorizontalRuler:YES];
    [_scrollView setHasVerticalRuler:YES];
    
    NSArray *rulerViews = @[[_scrollView horizontalRulerView], [_scrollView verticalRulerView]];
    for (NSRulerView *rv in rulerViews) {
        [rv setReservedThicknessForMarkers:0.0];
        [rv setReservedThicknessForAccessoryView:0.0];
        [rv setClientView:_canvasView];
        [rv setAccessoryView:nil];
        [rv setMeasurementUnits:@"Points"];
    }
    
    [self updateRulerVisible];
}


- (void)updateRulerVisible {
    EDAssert(_scrollView);

    BOOL visible = [[EDUserDefaults instance] rulersVisible];
    [_scrollView setRulersVisible:visible];
}


#pragma mark -
#pragma mark Notifications

- (void)rulersVisibleDidChange:(NSNotification *)n {
    [self updateRulerVisible];
}


- (void)gridVisibleDidChange:(NSNotification *)n {
    [_canvasView setNeedsDisplay:YES];
}


- (void)guidesVisibleDidChange:(NSNotification *)n {
    [_canvasView setNeedsDisplayInUserGuidesDirtyRect];
}


- (void)compositionZoomScaleDidChange:(NSNotification *)n {
    SZDocument *doc = [n object];
    if (doc == _document) {
        [self updateRulersForZoomScale];
        EDAssert(_zoomPopUpView);
        [_zoomPopUpView updateValue];
    }
}


- (void)compositionMetricsDidChange:(NSNotification *)n {
    SZDocument *doc = [n object];
    if (doc == _document) {
        [self updateCompositionMetricsPopUp];
    }
}


- (void)updateRulersForZoomScale {
    NSInteger idx = _document.zoomScaleIndex;
    NSString *unit = idx == 0 ? @"Points" : [NSString stringWithFormat:@"Points%ld", idx];
    
    NSArray *rulerViews = @[[_scrollView horizontalRulerView], [_scrollView verticalRulerView]];
    for (NSRulerView *rv in rulerViews) {
        [rv setMeasurementUnits:unit];
    }
}


- (void)updateCompositionMetricsPopUp {
    EDAssert(_document);
    NSInteger w = _document.metrics.width;
    NSInteger h = _document.metrics.height;
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Canvas: %ld x %ld", @""), w, h];
    EDAssert(_metricsButton);
    [_metricsButton setTitle:title];
}


#pragma mark -
#pragma mark Properties

- (void)setDocument:(SZDocument *)newDoc {
    if (newDoc != _document) {
        [self willChangeValueForKey:@"document"];
        
        _document = newDoc;
        
        if (_canvasView) {
            _canvasView.document = newDoc;
        }
        
        if (newDoc) {
            [self updateCompositionMetricsPopUp];
            [self updateRulersForZoomScale];
            
            EDAssert(_zoomPopUpView.popUpButton);
            //NSLog(@"%@", [_zoomPopUpView.popUpButton infoForBinding:@"selectedTag"]);
            [_zoomPopUpView.popUpButton bind:@"selectedTag" toObject:_document withKeyPath:@"zoomScaleIndex" options:nil];
            //NSLog(@"%@", [_zoomPopUpView.popUpButton infoForBinding:@"selectedTag"]);
            
            EDAssert(_gridPopUpView.popUpButton);
            [_gridPopUpView.popUpButton bind:@"selectedTag" toObject:_document withKeyPath:@"gridTolerance" options:nil];
            
            EDAssert(_gridPopUpView.checkbox);
            [_gridPopUpView.checkbox bind:@"value" toObject:_document withKeyPath:@"gridEnabled" options:nil];
        }

        [self didChangeValueForKey:@"document"];
    }
}

@end
