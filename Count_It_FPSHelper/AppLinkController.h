//
//  AppLinkController.h
//  Count_It
//
//  Created by Michael LaRandeau on 4/25/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppLinkProtocol.h"
#import "FPSControllerProtocol.h"
#import "FPSWindowController.h"

@interface AppLinkController : NSObject <NSXPCListenerDelegate,AppLinkProtocol>

@property NSXPCConnection *appConnection;
@property NSXPCConnection *helperConnection;
@property (weak) NSXPCListener *listener;
@property (weak) FPSWindowController *windowController;

-(void)connectToHelper;
-(void)toggleRecording:(BOOL)shouldRecord;

@end
