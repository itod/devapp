//
//  EDTransparentView.m
//  Editor
//
//  Created by Todd Ditchendorf on 7/1/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDToolbarProgressView.h"
#import "EDMainWindowController.h"

#define PROGRESS_SIDE 18.0

@implementation EDToolbarProgressView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.progressIndicator = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0.0, 0.0, PROGRESS_SIDE, PROGRESS_SIDE)] autorelease];
        //[_progressIndicator setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [_progressIndicator setStyle:NSProgressIndicatorSpinningStyle];
        [_progressIndicator setIndeterminate:YES];
        [_progressIndicator setDisplayedWhenStopped:NO];
        //[_progressIndicator setControlSize:NSSmallControlSize];
        
        [self addSubview:_progressIndicator];
    }
    
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self unbind:@"busy"];
    self.progressIndicator = nil;
    [self killAnimeTimer];
    [super dealloc];
}


- (void)layoutSubviews {
    EDAssert(_progressIndicator);
    EDAssert([_progressIndicator superview] == self);
    _progressIndicator.frame = [self progressIndicatorRectForBounds:[self bounds]];
}


- (CGRect)progressIndicatorRectForBounds:(CGRect)bounds {
    CGFloat w = PROGRESS_SIDE;
    CGFloat h = PROGRESS_SIDE;

    CGFloat x = bounds.size.width/2.0 - w/2.0;
    CGFloat y = bounds.size.height/2.0 - h/2.0;
    
    CGRect r = CGRectMake(x, y, w, h);
    return r;

}

#pragma mark -
#pragma mark Notifications

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    NSWindow *win = [self window];
    if (win) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:win];
        [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidResignMainNotification object:win];

        NSWindowController *wc = [win windowController];
        if (wc) { // this can be nil when fullscreen transitioning
            [self bind:@"busy" toObject:wc withKeyPath:@"busy" options:nil];
        } else {
            [self unbind:@"busy"];
        }
    }
}


- (void)removeFromSuperview {
    [self unbind:@"busy"];
    [super removeFromSuperview];
}


- (void)windowDidBecomeMain:(NSNotification *)n {
    if ([self window]) {
        [self setNeedsDisplay:YES];
    }
}


- (void)startAnimeTimer {
    EDAssertMainThread();
    [self killAnimeTimer];
    self.animeTimer = [NSTimer scheduledTimerWithTimeInterval:0.15 target:self selector:@selector(animeTimerFired:) userInfo:nil repeats:NO];
}


- (void)animeTimerFired:(NSTimer *)t {
    EDAssertMainThread();
    EDAssert(_progressIndicator);
    
    EDMainWindowController *wc = [[self window] windowController];
    wc.statusText = NSLocalizedString(@"Initializing Interpreter…", @"");

    [_progressIndicator startAnimation:nil];
}


- (void)killAnimeTimer {
    EDAssertMainThread();
    [_animeTimer invalidate];
    self.animeTimer = nil;
}


- (void)setBusy:(BOOL)busy {
    EDAssertMainThread();
    if (busy != _busy) {
        [self willChangeValueForKey:@"busy"];
        
        _busy = busy;
        
        if (_busy) {
            [self startAnimeTimer];
        } else {
            [self killAnimeTimer];
            [_progressIndicator stopAnimation:nil];

            EDMainWindowController *wc = [[self window] windowController];
            wc.statusText = wc.canStop ? NSLocalizedString(@"Running…", @"") : @"";
        }

        [self didChangeValueForKey:@"busy"];
    }
}

@end

