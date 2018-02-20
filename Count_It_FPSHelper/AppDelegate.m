//
//  AppDelegate.m
//  Count_It
//
//  Created by Michael LaRandeau on 4/26/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import "AppDelegate.h"
#import "AppLinkController.h"

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    //Initialize Window
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 25, 50) styleMask: NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
    self.controller = [[FPSWindowController alloc] initWithWindow:window];
    [self.controller windowDidLoad];
    [self.controller showWindow:nil];
    [self.controller.window orderFrontRegardless];
    //self.controller.fps.stringValue = @"0";
    
    //Initialize Listener for Main App
    self.listener = [NSXPCListener anonymousListener];
    self.appLink = [[AppLinkController alloc] init];
    self.listener.delegate = self.appLink;
    self.appLink.listener = self.listener;
    self.appLink.windowController = self.controller;
    [self.listener resume];
    
    //Initialize Notifications
    //[[NSWorkspace sharedWorkspace] addObserver:self forKeyPath:@"runningApplications" options:0 context:nil];
    
    //Initialize Controller to Link
    [self.controller.fps.record setTarget:self];
    [self.controller.fps.record setAction:@selector(toggleRecording:)];
    
    [self.appLink connectToHelper];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"runningApplications"]) {
        if (![self parentIsRunning]) {
            [[NSApplication sharedApplication] terminate:self];
        }
    }
}

-(BOOL)parentIsRunning {
    NSRunningApplication *parentApp = [NSRunningApplication runningApplicationWithProcessIdentifier:self.parentPID];
    if (parentApp == nil || [parentApp.bundleIdentifier isNotEqualTo:self.parentName]) { return NO; }
    else return YES;
}

-(void)toggleRecording:(FPSRecordButton *)record {
    BOOL shouldRecord = !record.isRecording;
    
    [self.appLink toggleRecording:shouldRecord];
    record.isRecording = shouldRecord;
}

@end
