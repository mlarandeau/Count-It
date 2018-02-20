//
//  AppTracerProtocol.h
//  Count_It
//
//  Created by Michael LaRandeau on 4/26/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AppTracerProtocol <NSObject>

- (void)attachToApp:(int)pid options:(NSDictionary *)options usingDTrace:(BOOL)useDTrace;
- (void)updateOptions:(NSDictionary *)options;
- (void)passEndpoint:(NSXPCListenerEndpoint *)endpoint;
- (void)shouldTerminate;

@end
