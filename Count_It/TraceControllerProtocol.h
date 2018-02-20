//
//  TraceControllerProtocol.h
//  Count_It
//
//  Created by Michael LaRandeau on 4/26/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TraceControllerProtocol <NSObject>

-(void)handleTraceOutput:(NSString *)data;
-(void)launchFPSHelper;
-(void)giveFPSEndpoint:(NSXPCListenerEndpoint *)endpoint;
-(void)errorHandler:(NSString *)error;

@end
