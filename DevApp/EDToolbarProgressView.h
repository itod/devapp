//
//  EDTransparentView.h
//  Editor
//
//  Created by Todd Ditchendorf on 7/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import <TDAppKit/TDView.h>

@interface EDToolbarProgressView : TDView

- (CGRect)progressIndicatorRectForBounds:(CGRect)bounds;

@property (nonatomic, retain) NSProgressIndicator *progressIndicator;
@property (nonatomic, assign) BOOL busy;
@property (nonatomic, retain) NSTimer *animeTimer;
@end
