//
//  EDActionArgumentsFacet.m
//  Editor
//
//  Created by Todd Ditchendorf on 10/18/13.
//  Copyright (c) 2013 Todd Ditchendorf. All rights reserved.
//

#import "EDActionArgumentsFacet.h"
#import "EDEnvironmentVariable.h"
#import "EDAction.h"
#import <TDAppKit/TDViewControllerView.h>

@interface EDActionArgumentsFacet ()

@end

@implementation EDActionArgumentsFacet

+ (NSString *)displayName {
    return NSLocalizedString(@"Arguments", @"");
}


- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}


- (void)dealloc {
    self.environmentVariables = nil;
    [super dealloc];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    TDViewControllerView *vcv = (TDViewControllerView *)self.view;
    [vcv setColor:[NSColor colorWithDeviceWhite:0.98 alpha:1.0]];
    
    self.environmentVariables = self.selectedAction.environmentVariables;
}


- (void)save {
//    self.selectedAction.environmentVariables = self.environmentVariables;
}


- (IBAction)insert:(id)sender {
    EDEnvironmentVariable *envVar = [[[EDEnvironmentVariable alloc] init] autorelease];
    [_arrayController addObject:envVar];
}


- (void)insertObject:(NSMutableDictionary *)envVar inEnvironmentVariablesAtIndex:(NSInteger)i {
    NSUndoManager *mgr = [[self.view window] undoManager];
    [[mgr prepareWithInvocationTarget:self] removeObjectFromEnvironmentVariablesAtIndex:i];
    
    [self startObservingEnvVar:envVar];
    [self.environmentVariables insertObject:envVar atIndex:i];
    [self save];
}


- (void)removeObjectFromEnvironmentVariablesAtIndex:(NSInteger)i {
    NSMutableDictionary *envVar = [self.environmentVariables objectAtIndex:i];
    
    NSUndoManager *mgr = [[self.view window] undoManager];
    [[mgr prepareWithInvocationTarget:self] insertObject:envVar inEnvironmentVariablesAtIndex:i];
    
    [self stopObservingEnvVar:envVar];
    [self.environmentVariables removeObjectAtIndex:i];
    [self save];
}


- (void)startObservingEnvVar:(NSMutableDictionary *)rule {
    [rule addObserver:self
           forKeyPath:@"name"
              options:NSKeyValueObservingOptionOld
              context:NULL];
    [rule addObserver:self
           forKeyPath:@"value"
              options:NSKeyValueObservingOptionOld
              context:NULL];
}


- (void)stopObservingEnvVar:(NSMutableDictionary *)rule {
    @try {
        [rule removeObserver:self forKeyPath:@"name"];
        [rule removeObserver:self forKeyPath:@"value"];
    } @catch (NSException *ex) {}
}


- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)v {
    [obj setValue:v forKeyPath:keyPath];
    [self save];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)obj change:(NSDictionary *)change context:(void *)ctx {
    EDAssertMainThread();
    EDAssert([obj isKindOfClass:[EDEnvironmentVariable class]]);

    if (obj == _arrayController && [@"selection" isEqualToString:keyPath]) {
        
    } else {
        NSUndoManager *mgr = [[self.view window] undoManager];
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        [[mgr prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:obj toValue:oldValue];
//        [self storeEnvironmentVariables]; // don't call -save here. causes infinite loop.
    }
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    [self save];
}


- (void)setEnvironmentVariables:(NSMutableArray *)newVars {
    NSMutableArray *oldVars = _environmentVariables;
    
    if (oldVars != newVars) {
        for (id var in oldVars) {
            [self stopObservingEnvVar:var];
        }
        
        [oldVars autorelease];
        _environmentVariables = [newVars retain];
        
        for (id var in newVars) {
            [self startObservingEnvVar:var];
        }
    }
}

@end
