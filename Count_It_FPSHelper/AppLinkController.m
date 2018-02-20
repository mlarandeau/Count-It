//
//  AppLinkController.m
//  Count_It
//
//  Created by Michael LaRandeau on 4/25/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import "AppLinkController.h"
#import "AppTracerProtocol.h"
#import "AppTracer.h"

@implementation AppLinkController


//NSXPCListenerDelegate Protocol
-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    self.appConnection = newConnection;
    self.appConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppLinkProtocol)];
    self.appConnection.exportedObject = self;
    AppLinkController * __weak weakSelf = self;
    self.appConnection.invalidationHandler = ^{ [weakSelf shouldTerminate]; };
    self.appConnection.interruptionHandler = ^{ [weakSelf shouldTerminate]; };
    self.appConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(FPSControllerProtocol)];
    [self.appConnection resume];
    if (self.helperConnection != nil) { [self.helperConnection invalidate]; self.helperConnection = nil;}
    return YES;
}

//Methods
-(void)connectToHelper {
    self.helperConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"MLaRandeau.Count-It-TraceHelper" options:NSXPCConnectionPrivileged];
    if (self.helperConnection != nil) {
        self.helperConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppTracerProtocol)];
        [self.helperConnection resume];
        [self.helperConnection.remoteObjectProxy passEndpoint:self.listener.endpoint];
    }
}

-(void)toggleRecording:(BOOL)shouldRecord {
    if (self.appConnection != nil) {
        [self.appConnection.remoteObjectProxy toggleBaseRecording:shouldRecord];
    }
}

//AppLinkProtocol
-(void)updateFrameRate:(NSString *)frameRate {
    [self.windowController updateFrameRate:frameRate];
}

-(void)updateBackgroundColor:(NSColor *)color {
    [self.windowController updateBackgroundColor:color];
}

-(void)updateRecordButtonFillColor:(NSColor *)color {
    [self.windowController updateRecordFillColor:color];
}

-(void)updateFontColor:(NSColor *)color {
    [self.windowController updateFontColor:color];
}

-(void)updateRecordButtonBorderColor:(NSColor *)color {
    [self.windowController updateRecordBorderColor:color];
}

-(void)updateFontSize:(double)height {
    [self.windowController updateFontSize:height];
}

-(void)updateFontName:(NSString *)fontName {
    [self.windowController updateFontName:fontName];
}

-(void)updateRoundedCorners:(BOOL)shouldUseRoundedCorners {
    [self.windowController updateRoundedCorners:shouldUseRoundedCorners];
}

-(void)updateDecimalPrecision:(int)precision {
    [self.windowController updatePrecision:precision];
}

-(void)toggleIsRecording:(BOOL)shouldRecord {
    [self.windowController toggleIsRecording:shouldRecord];
}

-(void)toggleShowRecordButton:(BOOL)shouldShow {
    [self.windowController toggleShowRecordingButton:shouldShow];
    [self.windowController reposition];
}

-(void)updateScreenPosition:(int)position {
    self.windowController.screenPosition = position;
    [self.windowController reposition];
}

-(void)shouldTerminate {
    [[NSApplication sharedApplication] terminate:self];
}

@end
