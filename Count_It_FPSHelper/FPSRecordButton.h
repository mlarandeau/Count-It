//
//  FPSRecordButton.h
//  Count_It
//
//  Created by Michael LaRandeau on 7/24/16.
//  Copyright © 2016 Michael LaRandeau. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FPSRecordButton : NSControl

@property NSColor *fillColor;
@property NSColor *borderColor;
@property BOOL isRecording;
@property BOOL isHighlighted;
@property BOOL isPressed;

@end
