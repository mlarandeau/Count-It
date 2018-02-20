//
//  FPSControllerProtocol.h
//  Count_It
//
//  Created by Michael LaRandeau on 4/26/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FPSControllerProtocol <NSObject>

-(void)connectToHelper:(NSXPCListenerEndpoint *)endpoint;
-(void)toggleBaseRecording:(BOOL)shouldRecord;

@end
