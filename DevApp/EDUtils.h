//
//  EDUtils.h
//  Editor
//
//  Created by Todd Ditchendorf on 7/2/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ZERO_COORD (-10.0e6)
#define EDMaxFloatPoint CGPointMake(MAXFLOAT, MAXFLOAT)
#define EDMaxFloatRect CGRectMake(ZERO_COORD, ZERO_COORD, MAXFLOAT, MAXFLOAT);
#define EDIsAngleBetween(angle, low, high) ((angle) >= (low) && (angle) <= (high))
#define EDGetAngleBetween(p1, p2) (EDR2D(atan2((p2).y - (p1).y, (p2).x - (p1).x)) + 180.0)

NSData *EDDataFromPlist(NSDictionary *plist, NSError **outErr);
NSDictionary *EDPlistFromData(NSData *data, NSError **outErr);

BOOL EDPointIsMaxFloat(CGPoint p);
BOOL EDRectIsZero(CGRect r);
BOOL EDSizeContainsSize(CGSize s1, CGSize s2);

CGRect EDRectOutset(CGRect r, CGFloat dx, CGFloat dy);
CGRect EDCombineRects(CGRect r1, CGRect r2);
CGRect EDRectStandardize(CGRect r);
CGRect EDRectStandardizeZero(CGRect r);

CGRect EDRectFloor(CGRect r);
CGRect EDRectFloorPlusHalf(CGRect r);
CGRect EDRectRoundPlusHalf(CGRect r);
CGRect EDRectRound(CGRect r);

CGPoint EDRectGetMidMidPoint(CGRect r);
CGPoint EDRectGetTopLefPoint(CGRect r);
CGPoint EDRectGetTopMidPoint(CGRect r);
CGPoint EDRectGetTopRitPoint(CGRect r);
CGPoint EDRectGetMidLefPoint(CGRect r);
CGPoint EDRectGetMidRitPoint(CGRect r);
CGPoint EDRectGetBotLefPoint(CGRect r);
CGPoint EDRectGetBotMidPoint(CGRect r);
CGPoint EDRectGetBotRitPoint(CGRect r);

void EDWriteWebURLsToPasteboard(NSString *URLString, NSString *title, NSPasteboard *pboard);
void EDWriteAllToPasteboard(NSString *URLString, NSString *title, NSPasteboard *pboard);

void EDDrawBreakpoint(CGContextRef ctx, CGRect frame, NSEdgeInsets insets, CGSize offset, CGGradientRef grad, NSColor *strokeColor, NSShadow *shadow);
void EDDrawColorCell(CGContextRef ctx, CGRect r, NSColor *fillColor, NSColor *strokeColor, BOOL isOn, BOOL isHi);

NSImage *EDIconForFile(NSString *absPath);
NSImage *EDDirtyIconForFile(NSString *absPath);

NSString *EDGetXAttr(NSString *absPath, NSString *name, NSError **outErr);
BOOL EDSetXAttr(NSString *absPath, NSString *name, NSString *value, NSError **outErr);