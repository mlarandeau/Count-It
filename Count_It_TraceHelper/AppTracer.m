//
//  AppTracer.m
//  Count_It
//
//  Created by Michael LaRandeau on 4/18/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <stdio.h>
#import <AppKit/NSRunningApplication.h>
#import "AppTracer.h"

@implementation AppTracer

//NSXPCListenerDelegate Protocol
-(BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    NSString *connectingProcessName = [self getAppNameFromPID:newConnection.processIdentifier];
    if (connectingProcessName != nil) {
        if ([connectingProcessName isEqualToString:@"MLaRandeau.Count-It"]) {
            self.appConnection = newConnection;
            
            self.parentPID = self.appConnection.processIdentifier;
            self.parentName = connectingProcessName;
            
            self.appConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppTracerProtocol)];
            self.appConnection.exportedObject = self;
            
            AppTracer * __weak weakSelf = self;
            self.appConnection.invalidationHandler = ^{ [weakSelf shouldTerminate]; };
            self.appConnection.interruptionHandler = ^{ [weakSelf shouldTerminate]; };
            
            self.appConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TraceControllerProtocol)];
            [self.appConnection resume];
            
            return YES;
        }
        else if ([connectingProcessName isEqualToString:@"MLaRandeau.Count-It-FPSHelper"]) {
            self.fpsConnection = newConnection;
            
            self.fpsConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(AppTracerProtocol)];
            self.fpsConnection.exportedObject = self;
            
            [self.fpsConnection resume];
            
            return YES;
        }
    }
    
    return NO;
}

//AppTracerProtocol Protocol
-(void)attachToApp:(int)pid options:(NSDictionary *)options usingDTrace:(BOOL)useDTrace {
    self.trackingPID = pid;
    self.trackingName = [self getAppNameFromPID:self.trackingPID];
    self.options = [[NSMutableDictionary alloc] initWithDictionary:options];
    
    if (useDTrace) {
        [self initializeDtraceHandler];
        
        if (self.dh == NULL) { exit(EXIT_FAILURE); }
        
        [self.appConnection.remoteObjectProxy launchFPSHelper];
        [self performSelectorOnMainThread:@selector(performWork) withObject:nil waitUntilDone:NO];
    }
    else {
        [self.appConnection.remoteObjectProxy launchFPSHelper];
    }
}

-(void)passEndpoint:(NSXPCListenerEndpoint *)endpoint {
    [self.appConnection.remoteObjectProxy giveFPSEndpoint:endpoint];
}

-(void)shouldTerminate {
    [self cleanup];
}

//dtrace Callbacks
int chew(const dtrace_probedata_t *data, void *arg) {
    return (DTRACE_CONSUME_THIS);
}

int chewrec(const dtrace_probedata_t *data, const dtrace_recdesc_t *rec, void *arg) {
    return (DTRACE_CONSUME_THIS);
}

//dtrace Methods
-(void)initializeDtraceHandler {
    //Create Handler
    
    int err;
    self.dh = dtrace_open(DTRACE_VERSION, 0, &err);
    if (self.dh == NULL) {
        NSString *message = [NSString stringWithFormat:@"ERROR: Cannot open dtrace library: %s",dtrace_errmsg(NULL, err)];
        [self.appConnection.remoteObjectProxy errorHandler:message];
        exit(1);
    }
    
    //Get Script as string
    dtrace_prog_t *prog;
    //Include both OpenGL and Metal
    prog = dtrace_program_strcompile(self.dh, [self getScript:YES includeMetal:YES], DTRACE_PROBESPEC_NAME, 0, 0, NULL);
    if (prog == NULL) {
        //Include just Metal
        prog = dtrace_program_strcompile(self.dh, [self getScript:NO includeMetal:YES], DTRACE_PROBESPEC_NAME, 0, 0, NULL);
    }
    if (prog == NULL) {
        //Include just OpenGL
        prog = dtrace_program_strcompile(self.dh, [self getScript:YES includeMetal:NO], DTRACE_PROBESPEC_NAME, 0, 0, NULL);
    }
    if (prog == NULL) {
        [self.appConnection.remoteObjectProxy errorHandler:@"ERROR: Failed to compile string or pid could not be found."];
        [self cleanup];
    }
    
    //Set Options
    [self setOptions];
    
    //Set Probe
    dtrace_proginfo_t info;
    if (dtrace_program_exec(self.dh, prog, &info) != 0) {
        [self.appConnection.remoteObjectProxy errorHandler:@"Could not set probes."];
        [self cleanup];
    }
    
    //Start Tracing
    if (dtrace_go(self.dh) != 0) {
        [self.appConnection.remoteObjectProxy errorHandler:@"ERROR: Could not run dtrace handler."];
        [self cleanup];
    }
}

-(void)setOptions {
    NSString *samplingRate = [self.options objectForKey:@"Sampling Rate"];
    if (samplingRate == nil) { samplingRate = @"1000ms"; }
    
    (void) dtrace_setopt(self.dh, "bufsize", "4m");
    (void) dtrace_setopt(self.dh, "switchrate", samplingRate.UTF8String);
}

-(void)updateOptions:(NSDictionary *)options {
    NSString *samplingRateKey = @"Sampling Rate";
    NSString *samplingRate = [options objectForKey:samplingRateKey];
    if (samplingRate != nil) {
        [self.options setValue:samplingRate forKey:samplingRateKey];
        (void) dtrace_setopt(self.dh, "switchrate", samplingRate.UTF8String);
    }
}

-(char *)getScript:(BOOL)includeOpenGL includeMetal:(BOOL)includeMetal {
    //This script assumes that a game will use either OpenGL or Metal for rendering
    
    NSString *pidString = [NSString stringWithFormat:@"%d",self.trackingPID];
    
    //Begin
    NSString *begin = @"BEGIN { i=timestamp; diff=0; }";
    
    //Probe
    NSString *openGLProbe = [[@"pid" stringByAppendingString:pidString] stringByAppendingString:@":OpenGL:CGLFlushDrawable:entry"];
    NSString *metalProbe = [[@"objc" stringByAppendingString:pidString] stringByAppendingString:@":CAMetalLayer:-nextDrawable:entry"];
    NSString *probe = @"";
    if (includeOpenGL) { probe = [probe stringByAppendingString:openGLProbe]; }
    if (includeMetal) {
        if (![probe isEqualToString:@""]) { probe = [probe stringByAppendingString:@","]; }
        probe = [probe stringByAppendingString:metalProbe];
    }
    
    //Callback
    NSString *callback = @"{ time = timestamp; diff = time - i; i = time; printf(\"%d\\n\",diff); }";
    
    //Error
    NSString *error = [[[@"ERROR /pid==" stringByAppendingString:pidString] stringByAppendingString:@"/"] stringByAppendingString:callback];
    
    //Full Script
    NSString *fullScript = [[[begin stringByAppendingString:probe] stringByAppendingString:callback] stringByAppendingString:error];
    const char *finalFullScript = [fullScript UTF8String];
    return strdup(finalFullScript);
}

-(void)performWork {
    if ([self runTrace]) {
        fflush(stdout);
        //if (![self shouldContinueWork]) { [self shouldTerminate]; }
    }
    [self performSelectorOnMainThread:@selector(performWork) withObject:nil waitUntilDone:NO];
}

-(BOOL)runTrace {
    dtrace_sleep(self.dh);
    switch (dtrace_work(self.dh, stdout, chew, chewrec, NULL)) {
        case DTRACE_WORKSTATUS_DONE:
            return NO;
            break;
        case DTRACE_WORKSTATUS_OKAY:
            break;
        case DTRACE_WORKSTATUS_ERROR:
            [self.appConnection.remoteObjectProxy errorHandler:@"ERROR: An error has occured while tracing."];
            [self cleanup];
            break;
        default:
            break;
    }
    return YES;
}

-(void)redirectSTDOUT {
    NSPipe *pipe = [NSPipe pipe];
    dup2([[pipe fileHandleForWriting] fileDescriptor], fileno(stdout));
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stdoutHandler:) name:NSFileHandleDataAvailableNotification object:[pipe fileHandleForReading]];
    [pipe.fileHandleForReading waitForDataInBackgroundAndNotify];
}

-(void)stdoutHandler:(NSNotification *)notification {
    NSString *output = [[NSString alloc] initWithData:[[notification object] availableData] encoding: NSUTF8StringEncoding];
    [self.appConnection.remoteObjectProxy handleTraceOutput:output];
    [[notification object] waitForDataInBackgroundAndNotify];
}

-(void)cleanup {
    if (dtrace_stop(self.dh) != 0) {
        [self.appConnection.remoteObjectProxy errorHandler:@"ERROR: Could not stop dtrace handler."];
        exit(EXIT_FAILURE);
    }
    dtrace_close(self.dh);
    exit(EXIT_SUCCESS);
}

//General Methods
-(BOOL)shouldContinueWork {
    NSRunningApplication *parent = [NSRunningApplication runningApplicationWithProcessIdentifier:self.parentPID];
    NSRunningApplication *tracking = [NSRunningApplication runningApplicationWithProcessIdentifier:self.trackingPID];
    if (parent == nil || tracking == nil) {
        return NO;
    }
    return YES;
}

-(NSString *)getAppNameFromPID:(pid_t)pid {
    NSRunningApplication *foundApp = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
    if (foundApp != nil) {
        if (foundApp.bundleIdentifier != nil) { return foundApp.bundleIdentifier; }
        else { return foundApp.localizedName; }
    }
    else { return nil; }
}


@end







