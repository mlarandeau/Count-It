//
//  main.m
//  Count_It_TraceHelper
//
//  Created by Michael LaRandeau on 4/12/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppTracer.h"
#include "libproc.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        
        AppTracer *tracer = [[AppTracer alloc] init];
        NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:bundleIdentifier];
        listener.delegate = tracer;
        [listener resume];
        
        [tracer redirectSTDOUT];
        
        CFRunLoopRun();
    }
    return 0;
}
