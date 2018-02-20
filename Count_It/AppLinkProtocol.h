//
//  AppLinkProtocol.h
//  Count_It
//
//  Created by Michael LaRandeau on 4/26/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol AppLinkProtocol <NSObject>

-(void)updateFrameRate:(NSString *) frameRate;
-(void)updateBackgroundColor:(NSColor *)color;
-(void)updateFontColor:(NSColor *)color;
-(void)updateRecordButtonFillColor:(NSColor *)color;
-(void)updateRecordButtonBorderColor:(NSColor *)color;
-(void)updateFontSize:(double)height;
-(void)updateFontName:(NSString *) fontName;
-(void)updateRoundedCorners:(BOOL)shouldUseRoundedCorners;
-(void)updateDecimalPrecision:(int)precision;
-(void)toggleIsRecording:(BOOL)shouldRecord;
-(void)toggleShowRecordButton:(BOOL)shouldShow;
-(void)updateScreenPosition:(int)position;
-(void)shouldTerminate;

@end
