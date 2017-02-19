//
//  EDUtils.m
//  Editor
//
//  Created by Todd Ditchendorf on 7/2/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDUtils.h"
#import "WebURLsWithTitles.h"
#import <TDAppKit/TDUtils.h>
#import <sys/xattr.h>

NSData *EDDataFromPlist(NSDictionary *plist, NSError **outErr) {
    return [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0 options:NSPropertyListMutableContainers error:outErr];
}


NSDictionary *EDPlistFromData(NSData *data, NSError **outErr) {
    return [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:nil error:outErr];
}


BOOL EDPointIsMaxFloat(CGPoint p) {
    return CGPointEqualToPoint(p, EDMaxFloatPoint);
}


BOOL EDRectIsZero(CGRect r) {
    return CGRectEqualToRect(r, CGRectZero);
}


BOOL EDSizeContainsSize(CGSize s1, CGSize s2) {
    return s1.width >= s2.width && s1.height >= s2.height;
}


CGRect EDRectOutset(CGRect r, CGFloat dx, CGFloat dy) {
    r.origin.x -= dx;
    r.origin.y -= dy;
    r.size.width += dx * 2.0;
    r.size.height += dy * 2.0;
    return r;
}


CGRect EDCombineRects(CGRect r1, CGRect r2) {
    CGRect result = CGRectZero;
    
    BOOL is1Zero = EDRectIsZero(r1);
    BOOL is2Zero = EDRectIsZero(r2);
    
    if (is1Zero && is2Zero) {
        // result = CGRectZero;
    } else if (is1Zero) {
        result = r2;
    } else if (is2Zero) {
        result = r1;
    } else {
        result = CGRectUnion(r1, r2);
    }
    
    return result;
}


CGRect EDRectStandardize(CGRect r) {
    //    if (isinf(r.origin.x)) {
    //        assert(0);
    //    }
    
#define MIN_SIDE 1.0
    if (r.size.width < MIN_SIDE) {
        r.size.width = MIN_SIDE;
    } else if (isinf(r.size.width)) {
        r.size.width = MIN_SIDE;
    } else if (isnan(r.size.width)) {
        r.size.width = MIN_SIDE;
    }
    if (r.size.height < MIN_SIDE) {
        r.size.height = MIN_SIDE;
    } else if (isinf(r.size.height)) {
        r.size.height = MIN_SIDE;
    } else if (isnan(r.size.height)) {
        r.size.height = MIN_SIDE;
    }
    r = EDRectFloor(r);
    r.size.width = floor(r.size.width);
    r.size.height = floor(r.size.height);
    return r;
}


CGRect EDRectStandardizeZero(CGRect r) {
    //    if (isinf(r.origin.x)) {
    //        assert(0);
    //    }
    
#define ZERO_MIN_SIDE 0.0
    if (r.size.width < ZERO_MIN_SIDE) {
        r.size.width = ZERO_MIN_SIDE;
    } else if (isinf(r.size.width)) {
        r.size.width = ZERO_MIN_SIDE;
    } else if (isnan(r.size.width)) {
        r.size.width = ZERO_MIN_SIDE;
    }
    if (r.size.height < ZERO_MIN_SIDE) {
        r.size.height = ZERO_MIN_SIDE;
    } else if (isinf(r.size.height)) {
        r.size.height = ZERO_MIN_SIDE;
    } else if (isnan(r.size.height)) {
        r.size.height = ZERO_MIN_SIDE;
    }
    r = EDRectFloor(r);
    r.size.width = floor(r.size.width);
    r.size.height = floor(r.size.height);
    return r;
}


CGRect EDRectFloor(CGRect r) {
    r.origin.x = floorf(r.origin.x);
    r.origin.y = floorf(r.origin.y);
    return r;
}


CGRect EDRectFloorPlusHalf(CGRect r) {
    r.origin.x = floorf(r.origin.x) + 0.5;
    r.origin.y = floorf(r.origin.y) + 0.5;
    return r;
}


CGRect EDRectRound(CGRect r) {
    r.origin.x = roundf(r.origin.x);
    r.origin.y = roundf(r.origin.y);
    return r;
}


CGRect EDRectRoundPlusHalf(CGRect r) {
    r.origin.x = roundf(r.origin.x) + 0.5;
    r.origin.y = roundf(r.origin.y) + 0.5;
    return r;
}


CGPoint EDRectGetMidMidPoint(CGRect r) {
    return CGPointMake(NSMidX(r), NSMidY(r));
}


CGPoint EDRectGetTopLefPoint(CGRect r) {
    return CGPointMake(NSMinX(r), NSMinY(r));
}


CGPoint EDRectGetTopMidPoint(CGRect r) {
    return CGPointMake(NSMidX(r), NSMinY(r));
}


CGPoint EDRectGetTopRitPoint(CGRect r) {
    return CGPointMake(NSMaxX(r), NSMinY(r));
}


CGPoint EDRectGetMidLefPoint(CGRect r) {
    return CGPointMake(NSMinX(r), NSMidY(r));
}


CGPoint EDRectGetMidRitPoint(CGRect r) {
    return CGPointMake(NSMaxX(r), NSMidY(r));
}


CGPoint EDRectGetBotLefPoint(CGRect r) {
    return CGPointMake(NSMinX(r), NSMaxY(r));
}


CGPoint EDRectGetBotMidPoint(CGRect r) {
    return CGPointMake(NSMidX(r), NSMaxY(r));
}


CGPoint EDRectGetBotRitPoint(CGRect r) {
    return CGPointMake(NSMaxX(r), NSMaxY(r));
}


void EDWriteWebURLsToPasteboard(NSString *URLString, NSString *title, NSPasteboard *pboard) {
    pboard = pboard ? pboard : [NSPasteboard generalPasteboard];
    
    NSArray *types = [NSArray arrayWithObject:WebURLsWithTitlesPboardType];
    [pboard declareTypes:types owner:nil];
    
    [WebURLsWithTitles writeURLs:[NSArray arrayWithObject:[NSURL URLWithString:URLString]]
                       andTitles:[NSArray arrayWithObject:title]
                    toPasteboard:pboard];
}


void EDWriteAllToPasteboard(NSString *URLString, NSString *title, NSPasteboard *pboard) {
    pboard = pboard ? pboard : [NSPasteboard generalPasteboard];
    
    NSArray *types = [NSArray arrayWithObjects:WebURLsWithTitlesPboardType, NSURLPboardType, NSStringPboardType, nil];
    [pboard declareTypes:types owner:nil];
    
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // write WebURLsWithTitlesPboardType type
    [WebURLsWithTitles writeURLs:[NSArray arrayWithObject:URL] andTitles:[NSArray arrayWithObject:title] toPasteboard:pboard];
    
    // write NSURLPboardType type
    [URL writeToPasteboard:pboard];
    
    // write NSStringPboardType type
    [pboard setString:URLString forType:NSStringPboardType];
}


void EDDrawBreakpoint(CGContextRef ctx, CGRect frame, NSEdgeInsets insets, CGSize offset, CGGradientRef grad, NSColor *strokeColor, NSShadow *shadow) {
#define ARROW_WIDTH 4.0

    frame.origin = TDDeviceFloorAlign(ctx, frame.origin);
    CGRect arrowRect = CGRectMake(TDNoop(frame.origin.x + insets.left),
                                  TDNoop(frame.origin.y + insets.top),
                                  round(CGRectGetWidth(frame) - (insets.left + insets.right)),
                                  round(CGRectGetHeight(frame) - (insets.top + insets.bottom)));
    
    arrowRect.origin.x += offset.width;
    arrowRect.origin.y += offset.height;
    
    CGPoint botLef = CGPointMake(NSMinX(arrowRect), NSMinY(arrowRect));
    CGPoint topLef = CGPointMake(NSMinX(arrowRect), NSMaxY(arrowRect));
    CGPoint topRit = CGPointMake(NSMaxX(arrowRect) - ARROW_WIDTH, NSMaxY(arrowRect));
    CGPoint midRit = CGPointMake(NSMaxX(arrowRect), NSMidY(arrowRect));
    CGPoint botRit = CGPointMake(NSMaxX(arrowRect) - ARROW_WIDTH, NSMinY(arrowRect));
    
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, botLef.x, botLef.y);
    CGPathAddLineToPoint(path, NULL, topLef.x, topLef.y);
    CGPathAddLineToPoint(path, NULL, topRit.x, topRit.y);
    CGPathAddLineToPoint(path, NULL, midRit.x, midRit.y);
    CGPathAddLineToPoint(path, NULL, botRit.x, botRit.y);
    CGPathCloseSubpath(path);
    
    CGContextSaveGState(ctx);
    [shadow set];
    CGContextAddPath(ctx, path);
    CGContextClip(ctx);
    CGContextDrawLinearGradient(ctx, grad, topLef, botLef, 0);
    CGContextRestoreGState(ctx);
    
    [strokeColor setStroke];
    
    CGContextSaveGState(ctx);
    CGContextAddPath(ctx, path);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
    
    CGPathRelease(path);
}


void EDDrawColorCell(CGContextRef ctx, CGRect r, NSColor *fillColor, NSColor *strokeColor, BOOL isOn, BOOL isHi) {
    // alhpa triangle
    CGFloat alpha = [fillColor alphaComponent];
    if (alpha < 0.99999) {
        CGContextSaveGState(ctx);
        CGPoint p1 = CGPointMake(TDFloorAlign(CGRectGetMinX(r)), TDFloorAlign(CGRectGetMaxY(r)));
        CGPoint p2 = CGPointMake(TDFloorAlign(CGRectGetMaxX(r)), TDFloorAlign(CGRectGetMaxY(r)));
        CGPoint p3 = CGPointMake(TDFloorAlign(CGRectGetMaxX(r)), TDFloorAlign(CGRectGetMinY(r)));
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, p1.x, p1.y);
        CGContextAddLineToPoint(ctx, p2.x, p2.y);
        CGContextAddLineToPoint(ctx, p3.x, p3.y);
        CGContextClosePath(ctx);
        
        // invert alpha
        alpha = 1.0 - alpha;
        [[strokeColor colorWithAlphaComponent:alpha] setFill];
        CGContextFillPath(ctx);
        CGContextRestoreGState(ctx);
    }

    [fillColor setFill];
    CGContextFillRect(ctx, r);
    
    [strokeColor setStroke];
    CGContextStrokeRect(ctx, r);    
}


NSImage *EDIconForFile(NSString *absPath) {
    NSString *ext = [absPath pathExtension];
    NSImage *icon = nil;
    
    if ([ext isEqualToString:@"py"]) {
        icon = [NSImage imageNamed:@"PyDoc"];
    } else {
        icon = [[NSWorkspace sharedWorkspace] iconForFile:absPath];
    }
    
    return icon;
}


NSImage *EDDirtyIconForFile(NSString *absPath) {
    assert([[NSThread currentThread] isMainThread]);
    
    static NSMutableDictionary *sCache = nil;
    if (!sCache) {
        sCache = [[NSMutableDictionary alloc] init];
    }
    
    NSString *ext = [absPath pathExtension];
    NSImage *icon = sCache[ext];
    
    if (!icon) {
        icon = [[EDIconForFile(absPath) copy] autorelease];
        
        CGSize imgSize = [icon size];
        CGRect imgRect = CGRectMake(0.0, 0.0, imgSize.width, imgSize.height);

        [icon lockFocus];
        [[NSColor colorWithDeviceWhite:0.0 alpha:0.33] setFill];
        NSRectFillUsingOperation(imgRect, NSCompositeSourceAtop);
        [icon unlockFocus];
        
        assert(icon);
        sCache[ext] = icon;
    }
    
    return icon;
}


NSString *EDGetXAttr(NSString *absPath, NSString *name, NSError **outErr) {
#define MY_XATTR_MAX_LEN 128

    NSString *value = nil;
    
    const char *zPath = [absPath fileSystemRepresentation];
    const char *zName = [name UTF8String];
    
    char buff[MY_XATTR_MAX_LEN] = { 0 };
    ssize_t len = getxattr(zPath, zName, buff, MY_XATTR_MAX_LEN, 0, 0);
    if (ENOATTR == errno) {
        // this is a pretty normal circumstance. Let's not log the error unless the user passed in an outErr
        if (outErr) {
            NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"Couldn't get extended attribute of %@: %s", @""), absPath, strerror(errno)];
            NSLog(@"%@", reason);
            id userInfo = @{NSLocalizedFailureReasonErrorKey: reason};
            *outErr = [NSError errorWithDomain:[[NSProcessInfo processInfo] processName] code:0 userInfo:userInfo];
        }
    }

    if (len < 1) {
        goto done;
    }
    
    value = [[[NSString alloc] initWithBytes:buff length:len encoding:NSUTF8StringEncoding] autorelease];
    if (![value length]) {
        assert(0);
        goto done;
    }
    
done:
    return value;
}


BOOL EDSetXAttr(NSString *absPath, NSString *name, NSString *value, NSError **outErr) {
    BOOL success = NO;
    
    const char *zPath  = [absPath fileSystemRepresentation];
    const char *zName  = [name UTF8String];
    const char *zValue = [value UTF8String];
    size_t len = strlen(zValue);
    
    success = setxattr(zPath, zName, zValue, len, 0, 0);
    if (ENOATTR == errno) {
        NSString *reason = [NSString stringWithFormat:NSLocalizedString(@"Couldn't get extended attribute of %@: %s", @""), absPath, strerror(errno)];
        NSLog(@"%@", reason);
        if (outErr) {
            id userInfo = @{NSLocalizedFailureReasonErrorKey: reason};
            *outErr = [NSError errorWithDomain:[[NSProcessInfo processInfo] processName] code:0 userInfo:userInfo];
        }
    }
    
    return success;
}
