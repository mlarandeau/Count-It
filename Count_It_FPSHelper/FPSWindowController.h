//
//  FPSWindowController.h
//  Count_It
//
//  Created by Michael LaRandeau on 4/25/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FPSDisplay.h"
#import "FPSRecordButton.h"

@interface FPSWindowController : NSWindowController

@property FPSDisplay *fps;
@property int screenPosition;
@property double fontSize;

-(void)updateFrameRate:(NSString *)frameRate;
-(void)updateBackgroundColor:(NSColor *)color;
-(void)updateRecordFillColor:(NSColor *)color;
-(void)updateFontColor:(NSColor *)color;
-(void)updateRecordBorderColor:(NSColor *)color;
-(void)updateSize;
-(void)updateFontName:(NSString *)fontName;
-(void)updateFontSize:(double)fontSize;
-(void)updatePrecision:(int)precision;
-(void)updateRoundedCorners:(BOOL)shouldUseRoundedCorners;
-(void)toggleIsRecording:(BOOL)shouldRecord;
-(void)toggleShowRecordingButton:(BOOL)shouldShow;
-(NSPoint)getPosition:(NSSize)size;
-(void)reposition;

@end
