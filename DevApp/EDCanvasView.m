//
//  EDCanvasView.m
//  Editor
//
//  Created by Todd Ditchendorf on 6/26/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDCanvasView.h"
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

#define CANVAS_MARGIN 50.0

#define DEFAULT_TOLERANCE 20
#define MIN_TOLERANCE 2
#define MAX_TOLERANCE 100

static NSDictionary *sHints = nil;

static NSColor *sCanvasFillColor = nil;
static NSColor *sCompositionFillColor = nil;
static NSColor *sCompositionStrokeColor = nil;
static NSColor *sGridColor = nil;
static NSColor *sGridHighlightColor = nil;

static NSShadow *sCompositionShadow = nil;

static CGColorSpaceRef sPatternColorSpace = NULL;

@interface NSToolbarPoofAnimator
+ (void)runPoofAtPoint:(NSPoint)p;
@end

@interface EDCanvasView ()
- (void)killTimer;
- (void)displayContextMenu:(NSTimer *)t;

- (void)leftMouseDownSingleClick:(NSEvent *)evt;
- (void)beginUndoGrouping;
- (void)endUndoGrouping;

- (void)userGuideDraggedEvent:(NSEvent *)evt atPoint:(CGPoint)p;
- (void)userGuideMouseUp:(NSEvent *)evt atPoint:(CGPoint)p;

- (CGFloat)currentScale;

- (void)updateRulersOffset;

@property (nonatomic, retain) NSTimer *timer;

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
        
        sCompositionShadow = [[NSShadow alloc] init];
        [sCompositionShadow setShadowBlurRadius:3.0];
        [sCompositionShadow setShadowOffset:NSMakeSize(0.0, -1.0)];
        [sCompositionShadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.6]];
        
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
    [self killTimer];
    
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


- (void)keyDown:(NSEvent *)evt {
    BOOL handled = NO;
//    NSLog(@"%@", evt);
//    NSLog(@"%d", [evt keyCode]);
    
    // space key
	if ([evt isSpaceKeyDown]) {
        if (![evt isARepeat]) {
            [self pushCursor:[NSCursor openHandCursor]];
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
        [self popCursor];
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
    	
    [self updateRulersOffset];
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
    CGRect bgRect = CGRectMake(TDFloorAlign(compBounds.origin.x), TDFloorAlign(compBounds.origin.y), round(compBounds.size.width), round(compBounds.size.height));
	
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

            [sCompositionStrokeColor setStroke];
            CGRect bgStrokeRect = CGRectMake(bgRect.origin.x - 1.0, bgRect.origin.y - 1.0, bgRect.size.width + 2.0, bgRect.size.height + 2.0);
            CGContextStrokeRect(ctx, bgStrokeRect);
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
        
        // draw Grid
        CGContextSaveGState(ctx); {
            [self drawGridInContext:ctx dirtyRect:[self convertRectToComposition:dirtyRect]];
        } CGContextRestoreGState(ctx); // after grid
        
        // draw user guides
        if ([[EDUserDefaults instance] guidesVisible]) {
            for (EDGuide *g in _document.userGuides) {
                [g drawInContext:ctx dirtyRect:[self convertRectToComposition:dirtyRect]];
            }
        }
    
    } CGContextRestoreGState(ctx); // after translate
}


static void EDDrawPatternFunc(void *info, CGContextRef ctx) {
    assert([[NSThread currentThread] isMainThread]);
    assert(ctx);

    CGRect rectA = CGRectMake(0.0, 0.0, 1.0, 1.0);
    CGRect rectB = CGRectMake(1.0, 1.0, 1.0, 1.0);
    const CGRect rects[2] = {rectA, rectB};
    CGContextFillRects(ctx, rects, 2);
}


- (void)updateGridPattern {
    EDAssertMainThread();
    EDAssert(_document);
    
    CGPatternCallbacks callbacks;
    callbacks.version = 0;
    callbacks.drawPattern = EDDrawPatternFunc;
    callbacks.releaseInfo = NULL;
    
    CGRect patRect = CGRectMake(0.0, 0.0, 2.0, 2.0);
    CGFloat gridSide = _document.gridTolerance;
    EDAssert(gridSide >= 1.0);
    
    CGAffineTransform xform = CGAffineTransformMakeScale(gridSide, gridSide);
    CGPatternRef pat = CGPatternCreate(NULL, patRect, xform, patRect.size.width, patRect.size.height, kCGPatternTilingConstantSpacingMinimalDistortion, false, &callbacks);
    EDAssert(pat);
    [self setGridPattern:pat];
    CGPatternRelease(pat);
}


- (void)drawBackgroundPatternInContext:(CGContextRef)ctx compFrame:(CGRect)compFrame compBounds:(CGRect)compBounds {
    EDAssertMainThread();
    if (!_gridPattern) return;
    
    CGPoint locInWin = [self convertPoint:compFrame.origin toView:nil];
    CGContextSetPatternPhase(ctx, CGSizeMake(locInWin.x, locInWin.y));
    
    EDAssert(sPatternColorSpace);
    CGContextSetFillColorSpace(ctx, sPatternColorSpace);
    
    EDAssert(_gridPattern);
    const CGFloat comps[1] = {0.92};
    CGContextSetFillPattern(ctx, _gridPattern, comps);
    CGContextFillRect(ctx, compBounds);
}


- (void)drawGridInContext:(CGContextRef)ctx dirtyRect:(CGRect)drect {
    if (!_document.isGridEnabled || ![[EDUserDefaults instance] gridVisible]) return;
    
    CGFloat scale = [_document zoomScale];
    CGFloat fudge = 0.5;//[self fudge];
    
    [NSBezierPath setDefaultLineWidth:1.0]; // / scale];
    
    CGRect frame = [self scaledCompositionBounds]; //compositionBounds];
    
    CGFloat dist = scale * _document.gridTolerance;
    if (dist < MIN_TOLERANCE || dist > MAX_TOLERANCE) return;
    
    CGFloat minX = floor(NSMinX(frame)) + fudge;
    CGFloat maxX = floor(NSMaxX(frame)) + fudge;
    CGFloat minY = floor(NSMinY(frame)) + fudge;
    CGFloat maxY = floor(NSMaxY(frame)) + fudge;
    
    NSInteger i = 0;
    
    NSInteger high = (NSInteger)ceil(frame.size.width / dist / 8.0);

    for (CGFloat x = NSMinX(frame); x <= NSMaxX(frame); x += dist, i++) {
        [((i % high == 0) ? sGridHighlightColor : sGridColor) setStroke];
        
        CGPoint p1 = CGPointMake(floor(x) + fudge, minY);
        CGPoint p2 = CGPointMake(floor(x) + fudge, maxY);
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
    
    i = 0;
    for (CGFloat y = NSMinY(frame); y <= NSMaxY(frame); y += dist, i++) {
        [((i % high == 0) ? sGridHighlightColor : sGridColor) setStroke];
        CGPoint p1 = CGPointMake(minX, floor(y) + fudge);
        CGPoint p2 = CGPointMake(maxX, floor(y) + fudge);
        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    }
    
//    for (CGFloat x = NSMidX(frame); x <= NSMaxX(frame); x += dist, i++) {
//        [((i % high == 0) ? sGridHighlightColor : sGridColor) setStroke];
//        
//        CGPoint p1 = CGPointMake(floor(x) + fudge, minY);
//        CGPoint p2 = CGPointMake(floor(x) + fudge, maxY);
//        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
//    }
//    
//    i = 0;
//    for (CGFloat x = NSMidX(frame); x >= NSMinX(frame); x -= dist, i++) {
//        if (i == 0) continue;
//        [((i % high == 0) ? sGridHighlightColor : sGridColor) setStroke];
//        
//        CGPoint p1 = CGPointMake(floor(x) + fudge, minY);
//        CGPoint p2 = CGPointMake(floor(x) + fudge, maxY);
//        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
//    }
//    
//    i = 0;
//    for (CGFloat y = NSMidY(frame); y <= NSMaxY(frame); y += dist, i++) {
//        [((i % high == 0) ? sGridHighlightColor : sGridColor) setStroke];
//        CGPoint p1 = CGPointMake(minX, floor(y) + fudge);
//        CGPoint p2 = CGPointMake(maxX, floor(y) + fudge);
//        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
//    }
//    
//    i = 0;
//    for (CGFloat y = NSMidY(frame); y >= NSMinY(frame); y -= dist, i++) {
//        if (i == 0) continue;
//        [((i % high == 0) ? sGridHighlightColor : sGridColor) setStroke];
//        CGPoint p1 = CGPointMake(minX, floor(y) + fudge);
//        CGPoint p2 = CGPointMake(maxX, floor(y) + fudge);
//        [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
//    }
    
}


#pragma mark -
#pragma mark Right Click

- (void)killTimer {
    if (_timer) {
        [_timer invalidate];
        self.timer = nil;
    }
}


- (void)displayContextMenu:(NSTimer *)t {
    NSEvent *evt = [_timer userInfo];
    
    NSEvent *click = [NSEvent mouseEventWithType:[evt type] 
                                        location:[evt locationInWindow]
                                   modifierFlags:[evt modifierFlags] 
                                       timestamp:[evt timestamp] 
                                    windowNumber:[evt windowNumber] 
                                         context:[evt context]
                                     eventNumber:[evt eventNumber] 
                                      clickCount:[evt clickCount] 
                                        pressure:[evt pressure]]; 
    
    NSMenu *menu = nil; //[[[self window] windowController] contextMenuForSelectionAtLocationInComposition:_lastClickedPoint];
    [NSMenu popUpContextMenu:menu withEvent:click forView:self];
    [self killTimer];
}


- (void)rightMouseDown:(NSEvent *)evt {
    _hasBegunUndoGroup = NO;

    _lastClickedPoint = [self locationInComposition:evt];

    [self leftMouseDownSingleClick:evt];

    self.timer = [NSTimer timerWithTimeInterval:0.0
                                         target:self 
                                       selector:@selector(displayContextMenu:) 
                                       userInfo:evt 
                                        repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
} 


#pragma mark -
#pragma mark Left Click

- (void)mouseDown:(NSEvent *)evt {
    [super mouseDown:evt];
    
    _hasMetDragThreshold = NO;
    _lastClickedPoint = [self locationInComposition:evt];

    if ([evt isControlKeyPressed]) {
        [self rightMouseDown:evt];
    } else {
        [self leftMouseDownSingleClick:evt];
    }
    
    if (_isDragScroll) {
        [self pushCursor:[NSCursor closedHandCursor]];
    }
}


- (void)leftMouseDownSingleClick:(NSEvent *)evt {
    //NSLog(@"%s %d", __PRETTY_FUNCTION__, [evt clickCount]);
    NSInteger clickCount = [evt clickCount];
    
    if (clickCount > 2) {
        return;
    }
        
    CGRect dirtyRect = CGRectZero;
    
    self.dragStartPoint = _lastClickedPoint;

    // check for dragScroll
    if (_isDragScroll) {
        return;
    }
    
    self.draggingUserGuide = [self userGuideAtPoint:_dragStartPoint];
    if (_draggingUserGuide) {
        [[self undoManager] beginUndoGrouping];
        return;
    }
    
    if (!CGRectIsEmpty(dirtyRect)) {
        [self setNeedsDisplayInRect:[self convertRectFromComposition:dirtyRect]];
    }
}


- (void)pushCursor:(NSCursor *)cursor {
    [cursor push];
    [[self enclosingScrollView] setDocumentCursor:[NSCursor currentCursor]];
}


- (void)popCursor {
    [[NSCursor currentCursor] pop];
    [[self enclosingScrollView] setDocumentCursor:[NSCursor currentCursor]];
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
        [self popCursor];
    }
    
    self.dragStartPoint = CGPointZero;
}



#pragma mark -
#pragma mark  Dragging

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


- (void)mouseDragged:(NSEvent *)evt {
    CGPoint p = [self locationInComposition:evt];
    
    if (_isDragScroll) {
        [self dragScrollToPoint:p];
        return;
    }
    
    if (_draggingUserGuide) {
        [self userGuideDraggedEvent:evt atPoint:p];
    }
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
    }
    
    [_draggingUserGuide moveToP1:p1 p2:p2];
    
    NSString *text = [NSString stringWithFormat:@"%0.f", f];
    
    [self showToolTipWithText:text];
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
    CGRect compBounds = CGRectMake(0.0, 0.0, _document.metrics.width, _document.metrics.height);
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
        x = viewBounds.size.width / 2.0 - compBounds.size.width / 2.0;
    } else {
        x = compBounds.size.width / 2.0 - viewBounds.size.width / 2.0;
    }
    if (viewBounds.size.height > compBounds.size.height) {
        y = viewBounds.size.height / 2.0 - compBounds.size.height / 2.0;
    } else {
        y = compBounds.size.height / 2.0 - viewBounds.size.height / 2.0;
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


- (void)rulerView:(NSRulerView *)ruler handleMouseDown:(NSEvent *)evt {
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

- (void)updateRulersOffset {
    CGPoint offset = [self scaledCompositionFrame].origin;
    [[self horizontalRulerView] setOriginOffset:offset.x];
    [[self verticalRulerView] setOriginOffset:offset.y];
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
        [self updateGridPattern];
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

            [self updateRulersOffset];
            [self updateGridPattern];
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
