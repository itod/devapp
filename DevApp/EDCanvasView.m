//
//  EDCanvasView.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/26/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDCanvasView.h"
#import "SZApplication.h"
#import "EDToolTip.h"
#import "EDGuide.h"
#import "EDMetrics.h"
#import "SZDocument.h"
#import <TDAppKit/NSEvent+TDAdditions.h>
#import <TDAppKit/NSArray+TDAdditions.h>
#import <TDAppKit/TDUtils.h>
#import "EDUtils.h"
#import <tgmath.h>

#define ALWAYS_REDRAW_ENTIRE_CANVAS 0
#define MIN_WIDTH 2.0
#define MIN_HEIGHT 2.0

#define CANVAS_MARGIN 0.0

#define DEFAULT_TOLERANCE 20
#define MIN_TOLERANCE 2
#define MAX_TOLERANCE 100

#define JotFloor floor

NSString * const EDCompositionRulerOriginDidChangeNotification = @"EDCompositionRulerOriginDidChangeNotification";

static NSDictionary *sHints = nil;

static NSColor *sCanvasFillColor = nil;
static NSColor *sCompositionFillColor = nil;
static NSColor *sCompositionStrokeColor = nil;
static NSColor *sGridColor = nil;
static NSColor *sGridHighlightColor = nil;

static CGColorSpaceRef sPatternColorSpace = NULL;

@interface NSToolbarPoofAnimator
+ (void)runPoofAtPoint:(NSPoint)p;
@end

@interface EDCanvasView ()
- (CGPatternRef)gridPattern;
- (void)setGridPattern:(CGPatternRef)gridPattern;
@end

@implementation EDCanvasView {
    BOOL _hasMetDragThreshold;
    BOOL _hasBegunUndoGroup;
    
    BOOL _isDragScroll;
    
    CGPoint _lastClickedPoint;
    CGPatternRef _gridPattern;
}


+ (CGFloat)margin {
    return CANVAS_MARGIN;
}


+ (void)initialize {
    if ([EDCanvasView class] == self) {
        sHints = [[NSDictionary alloc] initWithObjectsAndKeys:
                  @(NSImageInterpolationHigh), NSImageHintInterpolation,
                  nil];
        
        sCanvasFillColor = [[NSColor colorWithDeviceWhite:0.9 alpha:1.0] retain];
        sCompositionFillColor = [[NSColor colorWithDeviceWhite:1.0 alpha:1.0] retain];
        sCompositionStrokeColor = [[NSColor colorWithDeviceWhite:0.0 alpha:1.0] retain];
        sGridColor = [[NSColor colorWithDeviceWhite:0.94 alpha:0.75] retain];
        sGridHighlightColor = [[NSColor colorWithDeviceWhite:0.88 alpha:0.75] retain];
        
        CGColorSpaceRef graySpace = CGColorSpaceCreateDeviceGray();
        sPatternColorSpace = CGColorSpaceCreatePattern(graySpace);
        CGColorSpaceRelease(graySpace);
    }
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(compositionMetricsDidChange:) name:EDCompositionMetricsDidChangeNotification object:nil];
        [nc addObserver:self selector:@selector(compositionZoomScaleDidChange:) name:EDCompositionZoomScaleDidChangeNotification object:nil];
        [nc addObserver:self selector:@selector(compositionGridDidChange:) name:EDCompositionGridEnabledDidChangeNotification object:nil];
        [nc addObserver:self selector:@selector(compositionGridDidChange:) name:EDCompositionGridToleranceDidChangeNotification object:nil];
        [nc addObserver:self selector:@selector(compositionRulerOriginDidChange:) name:EDCompositionRulerOriginDidChangeNotification object:nil];
        
        NSTrackingAreaOptions opts = NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved|NSTrackingActiveInKeyWindow|NSTrackingInVisibleRect;
        NSTrackingArea *ta = [[[NSTrackingArea alloc] initWithRect:[self bounds] options:opts owner:self userInfo:nil] autorelease];
        [self addTrackingArea:ta];
    }
    
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

//    if (_document.userGuides) {
//        for (EDGuide *g in _document.userGuides) {
//            g.canvasView = nil;
//        }
//    }
    
    self.delegate = nil;
    self.document = nil;
    self.image = nil;
    self.toolTipObject = nil;
    self.draggingUserGuide = nil;

    [self setGridPattern:NULL];
    
    [super dealloc];
}


#pragma mark -
#pragma mark NSView

- (BOOL)isFlipped {
    return YES;
}


- (BOOL)acceptsFirstMouse:(NSEvent *)evt {
    return YES;
}


- (BOOL)acceptsFirstResponder { 
    return YES; 
}


#pragma mark -
#pragma mark NSResponder


- (void)keyDown:(NSEvent *)evt {
    BOOL handled = NO;
//    NSLog(@"%@", evt);
//    NSLog(@"%d", [evt keyCode]);
    
    // space key
	if ([evt isSpaceKeyDown]) {
        if (![evt isARepeat]) {
            [self setCursor:[NSCursor openHandCursor]];
        }
        _isDragScroll = YES;
        handled = YES;
    }
    
    if (!handled) {
        [super keyDown:evt];
    }
}


- (void)keyUp:(NSEvent *)evt {
    if (_isDragScroll) {
        [self setCursor:[NSCursor arrowCursor]];
        _isDragScroll = NO;
    }
    [super keyUp:evt];
}


// center composition in scrollview
- (void)setFrame:(NSRect)newFrame {
    NSClipView *cv = (NSClipView *)[self superview];
    CGSize superSize = [cv frame].size;

    CGFloat scale = [self currentScale];
    CGFloat margin = CANVAS_MARGIN * scale;
    
    CGRect compBounds = [self scaledCompositionBounds];
    CGSize compSize = compBounds.size;
    compSize.width += margin * 2.0;
    compSize.height += margin * 2.0;

    newFrame.size.width = MAX(compSize.width, superSize.width);
    newFrame.size.height = MAX(compSize.height, superSize.height);
    [super setFrame:newFrame];
    	
    [self updateRulersOrigin];
    [self scrollToCenter];
}


- (void)setNeedsDisplayInRect:(NSRect)dirtyRect {
#if ALWAYS_REDRAW_ENTIRE_CANVAS
    dirtyRect = [self bounds];
#endif
    [super setNeedsDisplayInRect:dirtyRect];
}


- (void)drawRect:(NSRect)dirtyRect {
    EDAssertMainThread();

    //CGRect bounds = [self bounds];
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGRect compFrame = [self scaledCompositionFrame];
    CGRect compBounds = [self scaledCompositionBounds];
    CGRect bgRect = CGRectMake(round(compBounds.origin.x), round(compBounds.origin.y), round(compBounds.size.width), round(compBounds.size.height));
	
    // FILL CANVAS BG
    CGContextSaveGState(ctx); {
        [sCanvasFillColor setFill];
        CGContextFillRect(ctx, dirtyRect);
    } CGContextRestoreGState(ctx);

    CGContextSaveGState(ctx); { // before trans
        CGContextTranslateCTM(ctx, compFrame.origin.x, compFrame.origin.y); // trans offset
       
        // FILL/STROKE COMP BG
        CGContextSaveGState(ctx); {
            [sCompositionFillColor setFill];
            CGContextFillRect(ctx, CGRectIntersection(bgRect, dirtyRect));

//            [sCompositionStrokeColor setStroke];
//            CGRect bgStrokeRect = CGRectMake(bgRect.origin.x - 1.0, bgRect.origin.y - 1.0, bgRect.size.width + 2.0, bgRect.size.height + 2.0);
//            CGContextStrokeRect(ctx, bgStrokeRect);
        } CGContextRestoreGState(ctx);
        
//        // BG PATTERN
//        CGContextSaveGState(ctx); {
//            [self drawBackgroundPatternInContext:ctx compFrame:compFrame compBounds:compBounds];
//        } CGContextRestoreGState(ctx); // after patterß
//
        CGContextSaveGState(ctx); { // before scale

            CGFloat scale = [self currentScale];
            CGContextScaleCTM(ctx, scale, scale); // scale zoom
                
            // draw composition
            if (_image) {
                CGSize imgSize = [_image size];
                
                CGRect srcRect = CGRectMake(0.0, 0.0, imgSize.width, imgSize.height);
                CGRect destRect = CGRectMake(0.0, 0.0, imgSize.width, imgSize.height);

                [_image drawInRect:destRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:sHints];
            }
           
        } CGContextRestoreGState(ctx); // after scale
        
        // draw user guides
        if ([[EDUserDefaults instance] guidesVisible]) {
            for (EDGuide *g in _document.userGuides) {
                [g drawInContext:ctx dirtyRect:[self convertRectToComposition:dirtyRect]];
            }
        }
    
    } CGContextRestoreGState(ctx); // after translate
}


//static void EDDrawPatternFunc(void *info, CGContextRef ctx) {
//    assert([[NSThread currentThread] isMainThread]);
//    assert(ctx);
//
//    CGRect rectA = CGRectMake(0.0, 0.0, 1.0, 1.0);
//    CGRect rectB = CGRectMake(1.0, 1.0, 1.0, 1.0);
//    const CGRect rects[2] = {rectA, rectB};
//    CGContextFillRects(ctx, rects, 2);
//}
//
//
//- (void)updateGridPattern {
//    EDAssertMainThread();
//    EDAssert(_document);
//
//    CGPatternCallbacks callbacks;
//    callbacks.version = 0;
//    callbacks.drawPattern = EDDrawPatternFunc;
//    callbacks.releaseInfo = NULL;
//
//    CGRect patRect = CGRectMake(0.0, 0.0, 2.0, 2.0);
//    CGFloat gridSide = _document.gridTolerance;
//    EDAssert(gridSide >= 1.0);
//
//    CGAffineTransform xform = CGAffineTransformMakeScale(gridSide, gridSide);
//    CGPatternRef pat = CGPatternCreate(NULL, patRect, xform, patRect.size.width, patRect.size.height, kCGPatternTilingConstantSpacingMinimalDistortion, false, &callbacks);
//    EDAssert(pat);
//    [self setGridPattern:pat];
//    CGPatternRelease(pat);
//}
//
//
//- (void)drawBackgroundPatternInContext:(CGContextRef)ctx compFrame:(CGRect)compFrame compBounds:(CGRect)compBounds {
//    EDAssertMainThread();
//    if (!_gridPattern) return;
//
//    CGPoint locInWin = [self convertPoint:compFrame.origin toView:nil];
//    CGContextSetPatternPhase(ctx, CGSizeMake(locInWin.x, locInWin.y));
//
//    EDAssert(sPatternColorSpace);
//    CGContextSetFillColorSpace(ctx, sPatternColorSpace);
//
//    EDAssert(_gridPattern);
//    const CGFloat comps[1] = {0.92};
//    CGContextSetFillPattern(ctx, _gridPattern, comps);
//    CGContextFillRect(ctx, compBounds);
//}


#pragma mark -
#pragma mark Mouse Events

- (void)mouseEntered:(NSEvent *)evt {
    [super mouseEntered:evt];
    [self.delegate canvas:self mouseEntered:evt];
}


- (void)mouseExited:(NSEvent *)evt {
    [super mouseExited:evt];
    [self.delegate canvas:self mouseExited:evt];
}


- (void)mouseMoved:(NSEvent *)evt {
    [super mouseMoved:evt];
    [self.delegate canvas:self mouseMoved:evt];
}


- (void)mouseDown:(NSEvent *)evt {
    [super mouseDown:evt];
    
    _hasMetDragThreshold = NO;
    _lastClickedPoint = [self locationInComposition:evt];

    if ([evt isControlKeyPressed]) {
        [self rightMouseDown:evt];
    } else if (_isDragScroll) {
        [self setCursor:[NSCursor closedHandCursor]];
    } else {
        [self leftMouseDownSingleClick:evt];
    }
}


- (void)mouseUp:(NSEvent *)evt {
    //NSLog(@"%s %d", __PRETTY_FUNCTION__, [evt clickCount]);
    _hasMetDragThreshold = NO;
    
    if ([evt clickCount] > 2) return;
    
    if (_hasBegunUndoGroup) {
        _hasBegunUndoGroup = NO;
        [self endUndoGrouping];
    }
    
    if (_draggingUserGuide) {
        CGPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
        [self userGuideMouseUp:evt atPoint:p];
        [self endUndoGrouping];
        return;
    }
    
    if (_isDragScroll) {
        [self setCursor:[NSCursor openHandCursor]];
    } else {
        [self.delegate canvas:self mouseUp:evt];
    }
    
    self.dragStartPoint = CGPointZero;
}


- (void)rightMouseDown:(NSEvent *)evt {
    [super rightMouseDown:evt];
    [self.delegate canvas:self mouseDown:evt];
}


- (void)rightMouseUp:(NSEvent *)evt {
    [super rightMouseUp:evt];
    [self.delegate canvas:self mouseUp:evt];
}


- (void)otherMouseDown:(NSEvent *)evt {
    [super otherMouseDown:evt];
    [self.delegate canvas:self mouseDown:evt];
}


- (void)otherMouseUp:(NSEvent *)evt {
    [super otherMouseUp:evt];
    [self.delegate canvas:self mouseUp:evt];
}


- (void)leftMouseDownSingleClick:(NSEvent *)evt {
    //NSLog(@"%s %d", __PRETTY_FUNCTION__, [evt clickCount]);
    NSInteger clickCount = [evt clickCount];
    
    if (clickCount > 2) {
        return;
    }
        
    CGRect dirtyRect = CGRectZero;
    
    self.dragStartPoint = _lastClickedPoint;

    self.draggingUserGuide = [self userGuideAtPoint:_dragStartPoint];
    if (_draggingUserGuide) {
        [[self undoManager] beginUndoGrouping];
        return;
    } else {
        [self.delegate canvas:self mouseDown:evt];
    }
    
    if (!CGRectIsEmpty(dirtyRect)) {
        [self setNeedsDisplayInRect:[self convertRectFromComposition:dirtyRect]];
    }
}


- (void)setCursor:(NSCursor *)cursor {
    [cursor set];
    [[self enclosingScrollView] setDocumentCursor:[NSCursor currentCursor]];
}


#pragma mark -
#pragma mark  Dragging

- (void)mouseDragged:(NSEvent *)evt {
    
    if (_isDragScroll) {
        CGPoint p = [self locationInComposition:evt];
        [self dragScrollToPoint:p];
    } else if (_draggingUserGuide) {
        CGPoint p = [self locationInComposition:evt];
        [self userGuideDraggedEvent:evt atPoint:p];
    } else {
        [self.delegate canvas:self mouseDragged:evt];
    }
}


- (BOOL)dragPointMeetsDragThreshold:(CGPoint)p {
    if (_hasMetDragThreshold) return YES;

#define DRAG_THRESHOLD 4.0
#define CONNECTED_LINE_DRAG_THRESHOLD 40.0
    
    CGFloat diffX = fabs(p.x - _lastClickedPoint.x);
    CGFloat diffY = fabs(p.y - _lastClickedPoint.y);
    CGFloat threshold = 0.0;
    
    CGFloat scale = [self currentScale];

    threshold = DRAG_THRESHOLD / scale;
    
    _hasMetDragThreshold = (diffX > threshold || diffY > threshold);

    return _hasMetDragThreshold;
}


- (void)dragScrollToPoint:(CGPoint)locInComposition {
    CGPoint startLocInCanvas = [self convertPointFromComposition:_lastClickedPoint];
    CGPoint locInCanvas = [self convertPointFromComposition:locInComposition];
    
    CGFloat dx = startLocInCanvas.x - locInCanvas.x;
    CGFloat dy = startLocInCanvas.y - locInCanvas.y;

    CGPoint origin = [self visibleRect].origin;
    CGPoint p = CGPointMake(origin.x + dx, origin.y + dy);
    [self scrollPoint:p];
}


#pragma mark -
#pragma mark  Undo

- (void)beginUndoGrouping {
    if (!_hasBegunUndoGroup) {
        _hasBegunUndoGroup = YES;
        [[self undoManager] beginUndoGrouping];
    }
}


- (void)endUndoGrouping {
    if ([[self undoManager] groupingLevel] > 0) {
        [[self undoManager] endUndoGrouping];
    }   
}


#pragma mark -
#pragma mark  User Guides

- (EDGuide *)userGuideAtPoint:(CGPoint)p {
    EDGuide *result = nil;
    
    BOOL visible = [[EDUserDefaults instance] guidesVisible];
    BOOL locked = [[EDUserDefaults instance] guidesLocked];

    if (visible && !locked) {
        for (EDGuide *g in _document.userGuides) {
            if ([g containsPoint:p]) {
                result = g;
                break;
            }
        }
    }
    
    return result;
}


- (void)addUserGuide:(EDGuide *)g {
    EDAssert(_document.userGuides);
    EDAssert(![_document.userGuides containsObject:g]);
    
    [[[self undoManager] prepareWithInvocationTarget:self] removeUserGuide:g];
    [[self undoManager] setActionName:NSLocalizedString(@"Add Guide", @"")];

    [_document.userGuides addObject:g];
}


- (void)removeUserGuide:(EDGuide *)g {
    EDAssert(_document.userGuides);
    EDAssert([_document.userGuides containsObject:g]);
    
    [[[self undoManager] prepareWithInvocationTarget:self] addUserGuide:g];
    [[self undoManager] setActionName:NSLocalizedString(@"Remove Guide", @"")];

    [_document.userGuides removeObject:g];

    //NSEvent *evt = [[self window] currentEvent];
    //CGPoint locInScreen = [[self window] convertBaseToScreen:[evt locationInWindow]];
    //[NSToolbarPoofAnimator runPoofAtPoint:locInScreen];
    
    NSScrollView *sv = [self enclosingScrollView];
    EDAssert(sv);
    [[sv horizontalRulerView] setNeedsDisplay:YES];
    [[sv verticalRulerView] setNeedsDisplay:YES];
}


- (void)setNeedsDisplayInUserGuidesDirtyRect {
    EDAssert(_document.userGuides);
    for (EDGuide *g in _document.userGuides) {
        [self setNeedsDisplayInRect:[self convertRectFromComposition:g.dirtyRect]];
    }
}


- (void)userGuideMouseUp:(NSEvent *)evt atPoint:(CGPoint)p {
    if (!CGRectContainsPoint([self bounds], p)) {
        [self removeUserGuide:_draggingUserGuide];
    }
    self.draggingUserGuide = nil;
    [self hideToolTip];
}


- (void)userGuideDraggedEvent:(NSEvent *)evt atPoint:(CGPoint)p {
    NSAssert(_draggingUserGuide, @"");
        
    CGRect zero = EDMaxFloatRect;
    
    CGFloat f;
    CGPoint p1, p2;
    
    BOOL isGridEnabled = _document.isGridEnabled;
    isGridEnabled = [evt isOptionKeyPressed] ? !isGridEnabled : isGridEnabled;

    BOOL isGridRelativeToCenter = NO; // TODO

    NSInteger snapTolerance = _document.gridTolerance;
    NSInteger fudge = 0;
    
    if ([_draggingUserGuide isVertical]) {
        f = floor(p.x);
        if (isGridEnabled) {
            if (isGridRelativeToCenter) {
                CGRect compFrame = [self scaledCompositionFrame];
                fudge = ((NSInteger)floor(NSMidX(compFrame))) % snapTolerance;
            }
            f = snapTolerance * round(f / snapTolerance) + fudge;
        }
        p1 = CGPointMake(f, NSMinY(zero));
        p2 = CGPointMake(f, MAXFLOAT);

        f = [self rulerOriginAdjustedPoint:CGPointMake(f, 0.0)].x;
    } else {
        f = floor(p.y);
        if (isGridEnabled) {
            if (isGridRelativeToCenter) {
                CGRect compFrame = [self scaledCompositionFrame];
                fudge = ((NSInteger)floor(NSMinY(compFrame))) % snapTolerance;
            }
            f = snapTolerance * round(f / snapTolerance) + fudge;
        }
        p1 = CGPointMake(NSMinX(zero), f);
        p2 = CGPointMake(MAXFLOAT, f);

        f = [self rulerOriginAdjustedPoint:CGPointMake(0.0, f)].y;
    }
    
    [_draggingUserGuide moveToP1:p1 p2:p2];
    
    NSString *text = [NSString stringWithFormat:@"%0.f", f];
    
    [self showToolTipWithText:text];
}


- (CGPoint)rulerOriginAdjustedPoint:(CGPoint)inPoint {
    CGPoint outPoint = inPoint;
    CGRect frame = self.frame;
    
    switch (self.document.rulerOriginCorner) {
        case TDRectCornerTopLef:
            outPoint = inPoint;
            break;
        case TDRectCornerTopMid:
            outPoint.x = JotFloor(inPoint.x - NSWidth(frame)*0.5);
            outPoint.y = inPoint.y;
            break;
        case TDRectCornerTopRit:
            outPoint.x = JotFloor(inPoint.x - NSWidth(frame));
            outPoint.y = inPoint.y;
            break;
            
        case TDRectCornerMidLef:
            outPoint.x = inPoint.x;
            outPoint.y = JotFloor(inPoint.y - NSHeight(frame)*0.5);
            break;
        case TDRectCornerMidMid:
            outPoint.x = JotFloor(inPoint.x - NSWidth(frame)*0.5);
            outPoint.y = JotFloor(inPoint.y - NSHeight(frame)*0.5);
            break;
        case TDRectCornerMidRit:
            outPoint.x = JotFloor(inPoint.x - NSWidth(frame));
            outPoint.y = JotFloor(inPoint.y - NSHeight(frame)*0.5);
            break;
            
        case TDRectCornerBotLef:
            outPoint.x = inPoint.x;
            outPoint.y = JotFloor(inPoint.y - NSHeight(frame));
            break;
        case TDRectCornerBotMid:
            outPoint.x = JotFloor(inPoint.x - NSWidth(frame)*0.5);
            outPoint.y = JotFloor(inPoint.y - NSHeight(frame));
            break;
        case TDRectCornerBotRit:
            outPoint.x = JotFloor(inPoint.x - NSWidth(frame));
            outPoint.y = JotFloor(inPoint.y - NSHeight(frame));
            break;
            
        default:
            TDAssert(0);
            break;
    }
    
    return outPoint;
}


- (void)hideToolTip {
    [_toolTipObject removeFromSuperview];
    [_toolTipObject setText:@""];
}


- (void)showToolTipWithText:(NSString *)text {
    if (!_toolTipObject) {
        self.toolTipObject = [[[EDToolTip alloc] initWithFrame:CGRectZero] autorelease];
    }

    [_toolTipObject setText:text];

    CGPoint p = [self convertPoint:[[[self window] currentEvent] locationInWindow] fromView:nil];
    
#define TOOL_TIP_OFFSET_X 12.0
#define TOOL_TIP_OFFSET_Y -3.0
    
#define TOOL_TIP_MIN_MARGIN 3.0
    
    CGSize ttSize = _toolTipObject ? [_toolTipObject size] : CGSizeZero;

    p.x += TOOL_TIP_OFFSET_X;
    p.y += TOOL_TIP_OFFSET_Y;
    
    BOOL draggingHorizUserGuide = _draggingUserGuide && ![_draggingUserGuide isVertical];
    if (draggingHorizUserGuide) {
        p.y += 8.0;
    }
    
    CGRect ttFrame = CGRectMake(p.x, p.y, ttSize.width, ttSize.height);
    
    CGRect bounds = [self bounds];

    if (NSMinX(ttFrame) < NSMinX(bounds)) {
        ttFrame.origin.x = TOOL_TIP_MIN_MARGIN;
    } else if (NSMaxX(ttFrame) > NSMaxX(bounds)) {
        ttFrame.origin.x = NSMaxX(bounds) - ttFrame.size.width;
    }
    if (NSMinY(ttFrame) < NSMinY(bounds)) {
        ttFrame.origin.y = TOOL_TIP_MIN_MARGIN;
    } else if (NSMaxY(ttFrame) > NSMaxY(bounds)) {
        ttFrame.origin.y = NSMaxY(bounds) - ttFrame.size.height;
    }

    [_toolTipObject setLocation:ttFrame.origin];

    [self addSubview:_toolTipObject];
}


#pragma mark -
#pragma mark Public

- (CGRect)compositionBounds {
    TDAssertMainThread();
    NSString *identifier = [[[self window] windowController] identifier];
    NSImage *img = [[SZApplication instance] sharedImageForIdentifier:identifier];

    CGSize imgSize = [img size];
    CGRect compBounds = CGRectMake(0.0, 0.0, imgSize.width, imgSize.height);
    return compBounds;
}


- (CGRect)scaledCompositionBounds {
    CGRect compBounds = [self compositionBounds];
    
    CGFloat scale = [self currentScale];
    CGAffineTransform xform = CGAffineTransformMakeScale(scale, scale);
    compBounds = CGRectApplyAffineTransform(compBounds, xform);
    
    return compBounds;
}


- (CGRect)scaledCompositionFrame {
    CGRect viewBounds = [self bounds];
    CGRect compBounds = [self scaledCompositionBounds];
    
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    
    if (viewBounds.size.width > compBounds.size.width) {
        x = viewBounds.size.width * 0.5 - compBounds.size.width * 0.5;
    } else {
        x = compBounds.size.width * 0.5 - viewBounds.size.width * 0.5;
    }
    if (viewBounds.size.height > compBounds.size.height) {
        y = viewBounds.size.height * 0.5 - compBounds.size.height * 0.5;
    } else {
        y = compBounds.size.height * 0.5 - viewBounds.size.height * 0.5;
    }
    
    // NOTE : do not align this rect. That will throw off the alignment in Python space.
//    x = TDFloorAlign(x);
//    y = TDFloorAlign(y);

    x = floor(x);
    y = floor(y);

    CGRect r = CGRectMake(x, y, compBounds.size.width, compBounds.size.height);
    return r;
}


- (NSPoint)locationInComposition:(NSEvent *)evt {
    CGPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
    p = [self convertPointToComposition:p];
    return p;
}


- (CGPoint)convertPointToComposition:(CGPoint)canvasPoint {
    CGPoint offset = [self scaledCompositionFrame].origin;

    CGFloat scale = [self currentScale];

    CGPoint compPoint = CGPointApplyAffineTransform(canvasPoint, CGAffineTransformMakeTranslation(-offset.x, -offset.y));

    compPoint = CGPointApplyAffineTransform(compPoint, CGAffineTransformMakeScale(1 / scale, 1 / scale));
    
    return compPoint;
}


- (CGPoint)convertPointFromComposition:(CGPoint)compPoint {
    CGPoint offset = [self scaledCompositionFrame].origin;

    CGFloat scale = [self currentScale];

    CGPoint canvasPoint = CGPointApplyAffineTransform(compPoint, CGAffineTransformMakeTranslation(offset.x, offset.y));

    canvasPoint = CGPointApplyAffineTransform(canvasPoint, CGAffineTransformMakeScale(scale, scale));

    return canvasPoint;
}


- (CGRect)convertRectToComposition:(CGRect)canvasRect {
    CGPoint offset = [self scaledCompositionFrame].origin;
    CGRect compRect = CGRectOffset(canvasRect, -offset.x, -offset.y);

    CGFloat scale = [self currentScale];

    CGAffineTransform xform = CGAffineTransformMakeScale(1 / scale, 1 / scale);
    compRect = CGRectApplyAffineTransform(compRect, xform);

    return compRect;
}


- (CGRect)convertRectFromComposition:(CGRect)compRect {
    CGFloat scale = [self currentScale];

    CGAffineTransform xform = CGAffineTransformMakeScale(scale, scale);
    CGRect canvasRect = CGRectApplyAffineTransform(compRect, xform);

    CGPoint offset = [self scaledCompositionFrame].origin;
    canvasRect = CGRectOffset(canvasRect, offset.x, offset.y);

    return canvasRect;
}


#pragma mark -
#pragma mark NSRulerMarkerClientViewDelegation

- (BOOL)rulerView:(NSRulerView *)ruler shouldMoveMarker:(NSRulerMarker *)marker {
    return NO;
}


- (void)rulerView:(NSRulerView *)rv handleMouseDown:(NSEvent *)evt {
    if (([evt type] == NSLeftMouseDown && [evt isControlKeyPressed]) || [evt type] == NSRightMouseDown) {
        //[self rulerView:rv handleRightClick:evt];
    } else {
        //[self rulerView:rv handleLeftClick:evt];
    }
}


- (void)rulerView:(NSRulerView *)rv handleRightClick:(NSEvent *)evt {
    TDPerformOnMainThreadAfterDelay(0.0, ^{
        NSEvent *click = [NSEvent mouseEventWithType:[evt type]
                                            location:[evt locationInWindow]
                                       modifierFlags:[evt modifierFlags]
                                           timestamp:[evt timestamp]
                                        windowNumber:[evt windowNumber]
                                             context:[evt context]
                                         eventNumber:[evt eventNumber]
                                          clickCount:[evt clickCount]
                                            pressure:[evt pressure]];
        
        NSMenu *ctxMenu = [[[NSMenu alloc] init] autorelease];
        
        NSMenuItem *originItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Ruler Origin", @"")
                                                             action:nil
                                                      keyEquivalent:@""] autorelease];
        
        NSMenu *originMenu = [[[NSMenu alloc] init] autorelease];
        
        for (NSInteger i = 0; i <= TDRectCornerBotRit; ++i) {
            NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:TDRectCornerGetDisplayName(i)
                                                           action:@selector(changeRulerOriginCorner:)
                                                    keyEquivalent:@""] autorelease];
            [item setTarget:self];
            [item setTag:i];
            [item setState:i == self.document.rulerOriginCorner ? NSOnState : NSOffState];
            [originMenu addItem:item];
        }
        
        [originItem setSubmenu:originMenu];
        [ctxMenu addItem:originItem];
        
        [NSMenu popUpContextMenu:ctxMenu withEvent:click forView:self];
    });
}


- (IBAction)changeRulerOriginCorner:(id)sender {
    TDAssertMainThread();
    
    TDRectCorner newCorner = [sender tag];
    self.document.rulerOriginCorner = newCorner;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:EDCompositionRulerOriginDidChangeNotification object:self];
}


- (void)rulerView:(NSRulerView *)ruler handleLeftClick:(NSEvent *)evt {
    BOOL visible = [[EDUserDefaults instance] guidesVisible];
    if (!visible) {
        [[EDUserDefaults instance] setGuidesVisible:YES];
        [self setNeedsDisplayInUserGuidesDirtyRect];
    }
    
    BOOL isVert = ruler == [self verticalRulerView];
    
    CGRect zero = EDMaxFloatRect;
    //CGRect zero = [self convertRectToComposition:[self bounds]];

    CGPoint p1 = zero.origin;
    CGPoint p2;

    if (isVert) {
        p2 = CGPointMake(zero.origin.x, MAXFLOAT);
    } else {
        p2 = CGPointMake(MAXFLOAT, zero.origin.y);
    }

    self.draggingUserGuide = [EDGuide guideWithCanvas:self type:EDGuideTypeUser from:p1 to:p2];
    [self addUserGuide:_draggingUserGuide];
    
    while (1) {
        NSEvent *evt = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask|NSLeftMouseUpMask 
                                          untilDate:[NSDate distantFuture] 
                                             inMode:NSEventTrackingRunLoopMode 
                                            dequeue:YES];
        
        CGPoint p = [self convertPoint:[evt locationInWindow] fromView:nil];
        if ([evt type] == NSLeftMouseDragged) {
            [self userGuideDraggedEvent:evt atPoint:[self convertPointToComposition:p]];
        } else {
            [self userGuideMouseUp:evt atPoint:p];
            break;
        }
    }
    
}


- (void)updateRulersOrigin {
    //CGPoint origin = [self compositionOrigin];
    CGRect compRect = [self scaledCompositionFrame];
    CGPoint origin = TDRectGetCornerPoint(compRect, self.document.rulerOriginCorner);
    [[self horizontalRulerView] setOriginOffset:origin.x];
    [[self verticalRulerView] setOriginOffset:origin.y];
}


- (NSRulerView *)verticalRulerView {
    return [[self enclosingScrollView] verticalRulerView];
}


- (NSRulerView *)horizontalRulerView {
    return [[self enclosingScrollView] horizontalRulerView];
}


- (void)scrollToCenter {
    EDAssert([self enclosingScrollView]);
    
    CGPoint p = EDRectGetMidMidPoint([self bounds]);
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, NSStringFromPoint(p));
    CGRect r = CGRectMake(p.x - 1.0, p.y - 1.0, 2.0, 2.0);
    [self scrollRectToCenter:r];
}


- (void)scrollRectToCenter:(CGRect)objRect {
    EDAssert([self enclosingScrollView]);

    CGRect visRect = [self visibleRect];
    
    if (!CGRectContainsRect(visRect, objRect)) {
        if (EDSizeContainsSize(visRect.size, objRect.size)) {
            CGPoint p = EDRectGetMidMidPoint(objRect);
            objRect = CGRectMake(p.x - visRect.size.width / 2.0, p.y - visRect.size.height / 2.0, visRect.size.width, visRect.size.height);
        }
        
        [self scrollRectToVisible:objRect];
    }
}


#pragma mark -
#pragma mark Private

- (void)compositionMetricsDidChange:(NSNotification *)n {
    SZDocument *doc = [n object];
    if (doc == _document) {
        [self updateForZoomScale];
    }
}


- (void)compositionZoomScaleDidChange:(NSNotification *)n {
    SZDocument *doc = [n object];
    if (doc == _document) {
        [self updateForZoomScale];
    }
}


- (void)compositionGridDidChange:(NSNotification *)n {
    SZDocument *doc = [n object];
    if (doc == _document) {
//        [self updateGridPattern];
        [self setNeedsDisplay:YES];
    }
}


- (void)compositionRulerOriginDidChange:(NSNotification *)n {
    EDCanvasView *canvas = [n object];
    TDAssert([canvas isKindOfClass:[EDCanvasView class]]);
    if (canvas == self) {
        [self updateRulersOrigin];
        [self setNeedsDisplay:YES];
    }
}


- (void)updateForZoomScale {    
    // this giggles the scrollview and rulerviews
    [self setFrame:[self frame]];
    
    // center on the center of canvas after zoom
    CGRect bounds = [self bounds];
    CGRect centerRect = NSMakeRect(NSMidX(bounds) - 0.5, NSMidY(bounds) - 0.5, 1.0, 1.0);
    
    [self scrollRectToCenter:centerRect];
    
    // force redaw entire canvas (gray area may have grown considerably)
    [self setNeedsDisplay:YES];
}


- (CGFloat)currentScale {
    CGFloat scale = 1.0;
    
    if (_document) scale = _document.zoomScale;
    
    NSAssert(scale > 0.0, @"");
    scale = scale == 0.0 ? 1.0 : scale;

    return scale;
}


- (void)setDocument:(SZDocument *)document {
    if (document != _document) {
        
//        if (_document) {
//            for (EDGuide *g in _document.userGuides) {
//                g.canvasView = nil;
//            }
//        }
        
        _document = document;
        
        if (_document) {
            EDAssert(_document.userGuides);
            for (EDGuide *g in _document.userGuides) {
                g.canvasView = self;
            }

            [self updateRulersOrigin];
//            [self updateGridPattern];
            [self scrollToCenter];
        }
    }
}


- (CGPatternRef)gridPattern {
    return _gridPattern;
}


- (void)setGridPattern:(CGPatternRef)gridPattern {
    if (_gridPattern != gridPattern) {
        CGPatternRelease(_gridPattern);
        _gridPattern = CGPatternRetain(gridPattern);
    }
}

@end
