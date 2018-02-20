//
//  AppTracer.h
//  Count_It
//
//  Created by Michael LaRandeau on 4/18/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "dtrace.h"
#include "libproc.h"
#include "AppTracerProtocol.h"
#include "TraceControllerProtocol.h"

@interface AppTracer : NSObject <AppTracerProtocol,NSXPCListenerDelegate>

@property (weak) NSXPCConnection *appConnection;
@property (weak) NSXPCConnection *fpsConnection;
@property dtrace_hdl_t *dh;
@property int trackingPID;
@property NSString *trackingName;
@property int parentPID;
@property NSString *parentName;
@property NSMutableDictionary *options;

-(void)initializeDtraceHandler;
-(void)setOptions;
-(char *)getScript: (BOOL)includeOpenGL includeMetal:(BOOL)includeMetal;
-(void)performWork;
-(BOOL)runTrace;
-(BOOL)shouldContinueWork;
-(void)redirectSTDOUT;
-(void)stdoutHandler: (NSNotification *)notification;
-(void)cleanup;

@end
