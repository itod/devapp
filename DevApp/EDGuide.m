//
//  EDGuide.m
//  Editor
//
//  Created by Todd Ditchendorf on 11/27/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "EDGuide.h"
#import "EDUserDefaults.h"
#import "EDCanvasView.h"
#import "SZDocument.h"
#import "EDUtils.h"

static NSColor *sCanvasColor = nil;
static NSColor *sObjectColor = nil;
static NSColor *sUserColor = nil;

@interface EDGuide ()
- (NSUndoManager *)undoManager;
@end

@implementation EDGuide

+ (void)initialize {
    if ([EDGuide class] == self) {
        sCanvasColor = [[[NSColor magentaColor] colorWithAlphaComponent:0.5] retain];
        sObjectColor = [[NSColor colorWithDeviceRed:255.0/255.0 green:222.0/255.0 blue:70.0/255.0 alpha:1.0] retain];
        sUserColor = [[[NSColor cyanColor] colorWithAlphaComponent:1.0] retain];
    }
}


+ (EDGuide *)guideWithCanvas:(EDCanvasView *)c type:(EDGuideType)t from:(CGPoint)inP1 to:(CGPoint)inP2 {
    EDGuide *guide = [[[EDGuide alloc] initWithCanvas:c type:t from:inP1 to:inP2] autorelease];
    return guide;    
}


- (id)initWithCanvas:(EDCanvasView *)c type:(EDGuideType)t from:(CGPoint)inP1 to:(CGPoint)inP2 {
    if (self = [super init]) {
        self.canvasView = c;
        self.type = t;
        self.p1 = EDMaxFloatPoint;
        self.p2 = EDMaxFloatPoint;
        
        if ([self isUserGuide]) {
            [self moveToP1:EDMaxFloatPoint p2:EDMaxFloatPoint];
        }
        
        CGPoint newp1 = inP1; //CGPointMake(floorf(inP1.x) + 0.5, floorf(inP1.y) + 0.5);
        CGPoint newp2 = inP2; //CGPointMake(floorf(inP2.x) + 0.5, floorf(inP2.y) + 0.5);

        if ([self isUserGuide]) {
            [self moveToP1:newp1 p2:newp2];
        } else {
            self.p1 = newp1;
            self.p2 = newp2;
        }
    }
    return self;
}


- (instancetype)initFromPlist:(NSDictionary *)plist {
    self = [super init];
    if (self) {
        self.type = [plist[@"type"] integerValue];
        self.p1 = NSPointFromString(plist[@"p1"]);
        self.p2 = NSPointFromString(plist[@"p2"]);
    }
    return self;
}


- (NSDictionary *)asPlist {
    return @{@"type": @(_type),
             @"p1": NSStringFromPoint(_p1),
             @"p2": NSStringFromPoint(_p2),
             };
}


//- (id)initWithCoder:(NSCoder *)coder {
//    self.type = [coder decodeIntegerForKey:@"type"];
//    self.p1 = NSPointFromString([coder decodeObjectForKey:@"p1"]);
//    self.p2 = NSPointFromString([coder decodeObjectForKey:@"p2"]);
//    return self;
//}
//
//
//- (void)encodeWithCoder:(NSCoder *)coder {
//    [coder encodeInteger:_type forKey:@"type"];
//    [coder encodeObject:NSStringFromPoint(_p1) forKey:@"p1"];
//    [coder encodeObject:NSStringFromPoint(_p2) forKey:@"p2"];
//}


- (void)dealloc {
    self.canvasView = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p {%@,%@}>", [self class], self, NSStringFromPoint(_p1), NSStringFromPoint(_p2)];
}


- (NSUndoManager *)undoManager {
    return [_canvasView undoManager];
}


- (void)moveToP1:(CGPoint)newp1 p2:(CGPoint)newp2 {
    //NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, NSStringFromPoint(newp1), NSStringFromPoint(newp2));
    
    BOOL hasOldLoc = ![self isOffscreen];

    if (hasOldLoc) {
        [[[self undoManager] prepareWithInvocationTarget:self] moveToP1:_p1 p2:_p2];
        [[self undoManager] setActionName:NSLocalizedString(@"Move Guide", @"")];

        CGRect dirtyRect = self.dirtyRect;
        [_canvasView setNeedsDisplayInRect:dirtyRect];
    }

    CGRect oldDirtyRect = self.dirtyRect;
    CGPoint oldPoint = [self scaledP1]; // self.p1;

    self.p1 = newp1;
    self.p2 = newp2;
    
    if (!EDPointIsMaxFloat(oldPoint)) {
        [_canvasView.delegate canvas:_canvasView didMoveUserGuide:self from:oldPoint to:[self scaledP1]]; // self.p1
    }

    if ([self isOffscreen]) {
        //[canvas removeUserGuide:self];
    } else {
//        [_canvasView setNeedsDisplay:YES];
        [_canvasView setNeedsDisplayInRect:[_canvasView convertRectFromComposition:EDCombineRects(oldDirtyRect, self.dirtyRect)]];
//        [_canvasView setNeedsDisplayInRect:[_canvasView.delegate visibleRectForCanvas:_canvasView]]; // TODO totally unnecessary drawing happening here. this is needed for semi-opaque images when guides overlap them :(
    }
}


- (void)drawInContext:(CGContextRef)ctx dirtyRect:(CGRect)drect {
    NSColor *c = nil;

    switch (_type) {
        case EDGuideTypeCanvasBounds:
            c = sCanvasColor;
            break;
        case EDGuideTypeObjectBounds:
            c = sObjectColor;
            break;
        case EDGuideTypeUser:
            c = sUserColor;
            break;
        default:
            NSAssert(0, @"unknown guide type");
            break;
    }
    
    [c setStroke];
    
    // if drawn while ctx scaled
//    CGFloat scale = _canvasView.document.zoomScale;
//    CGContextSetLineWidth(ctx, 1.0 / scale);
//    CGContextBeginPath(ctx);
//    CGContextMoveToPoint(ctx, floor(_p1.x) + 0.5, floor(_p1.y) + 0.5);
//    CGContextAddLineToPoint(ctx, floor(_p2.x) + 0.5, floor(_p2.y) + 0.5);

    // if drawn not while ctx scaled
    CGPoint p1 = [self scaledP1];
    CGPoint p2 = [self scaledP2];
    
    CGContextSetLineWidth(ctx, 1.0);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, floor(p1.x) + 0.5, floor(p1.y) + 0.5);
    CGContextAddLineToPoint(ctx, floor(p2.x) + 0.5, floor(p2.y) + 0.5);

    CGContextStrokePath(ctx);
}


- (BOOL)isSelected {
    return NO;
}


- (BOOL)isShape {
    return NO;
}


- (BOOL)isConnectedTo:(id)obj {
    return NO;
}


- (CGRect)dirtyRect {
    if ([self isVertical]) {
        return CGRectMake(_p1.x - 1.0, _p1.y - 1.0, 2.0, _p2.y - _p1.y + 2.0);
    } else {
        return CGRectMake(_p1.x - 1.0, _p1.y - 1.0, _p2.x - _p1.x + 2.0, 2.0);
    }
}


- (CGRect)frame {
    if ([self isVertical]) {
        return EDRectStandardizeZero(CGRectMake(_p1.x, _p1.y, 0.0, _p2.y - _p1.y));
    } else {
        return EDRectStandardizeZero(CGRectMake(_p1.x, _p1.y, _p2.x - _p1.x, 0.0));
    }
}


- (CGFloat)currentScale {
    CGFloat scale = 1.0;
    
#if SCALE_HANDLES
    if (_canvasView) scale = _canvasView.zoomScale;
    NSAssert(scale > 0.0, @"");
    scale = scale == 0.0 ? 1.0 : scale;
#endif
    
    return scale;
}


- (BOOL)containsPoint:(CGPoint)p {
    CGFloat scale = [self currentScale];
    CGFloat radius = 1.0 / scale;
    return CGRectContainsPoint(EDRectOutset([self dirtyRect], radius, radius), p);
}


- (BOOL)isVertical {
    return fabs(_p2.y - _p1.y) > 2.0;
}


- (BOOL)isUserGuide {
    return EDGuideTypeUser == _type;
}


- (BOOL)isOffscreen {
    return EDPointIsMaxFloat(_p1) && EDPointIsMaxFloat(_p2);
}


- (CGPoint)scaledP1 {
    EDAssert(_canvasView);
    CGFloat scale = _canvasView.document.zoomScale;
    return CGPointMake(_p1.x * scale, _p1.y * scale);
}


- (CGPoint)scaledP2 {
    EDAssert(_canvasView);
    CGFloat scale = _canvasView.document.zoomScale;
    return CGPointMake(_p2.x * scale, _p2.y * scale);
}


- (void)setP1:(CGPoint)p {
    _p1 = p; //CGPointMake(floor(p.x) + 0.5, floor(p.y) + 0.5);
}


- (void)setP2:(CGPoint)p {
    _p2 = p; //CGPointMake(floor(p.x) + 0.5, floor(p.y) + 0.5);
}

@end
