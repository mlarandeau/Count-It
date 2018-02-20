//
//  AppDelegate.h
//  Count_It
//
//  Created by Michael LaRandeau on 4/26/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FPSWindowController.h"
#import "AppLinkController.h"
#import "FPSRecordButton.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property pid_t parentPID;
@property NSString *parentName;
@property FPSWindowController *controller;
@property AppLinkController *appLink;
@property NSXPCListener *listener;

-(BOOL)parentIsRunning;
-(void)toggleRecording:(FPSRecordButton *)record;

@end
