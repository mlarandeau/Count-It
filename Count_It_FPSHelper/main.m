//
//  main.m
//  Count_It_FPSHelper
//
//  Created by Michael LaRandeau on 4/25/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppLinkController.h"
#import "FPSWindowController.h"
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc == 3) {
            AppDelegate *appDelegate = [[AppDelegate alloc] init];
            appDelegate.parentPID = atoi(argv[1]);
            appDelegate.parentName = [NSString stringWithUTF8String:argv[2]];
            if ([appDelegate.parentName isNotEqualTo:@"MLaRandeau.Count-It"]) { exit(EXIT_FAILURE); }
            
            [[NSApplication sharedApplication] setDelegate:appDelegate];
            [[NSApplication sharedApplication] run];
        }
    }
    return 0;
}
