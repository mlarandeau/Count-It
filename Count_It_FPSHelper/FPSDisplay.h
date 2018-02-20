//
//  FPSDisplay.h
//  Count_It
//
//  Created by Michael LaRandeau on 2/18/16.
//  Copyright © 2016 Michael LaRandeau. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FPSLabel.h"
#import "FPSRecordButton.h"

@interface FPSDisplay : NSView

@property FPSLabel *label;
@property FPSRecordButton *record;

@property NSColor *backgroundColor;
@property BOOL useRoundedCorners;
@property int digits;
@property int precision;
@property BOOL showRecordingButton;

@property NSString *count;
@property NSFont *font;
@property NSColor *fontColor;

-(NSSize)getCountSize:(CGFloat)fontSize precision:(int)precision;
-(void)updateFontWithName:(NSString *)fontName;
-(void)updateFontWithSize:(double)fontSize;

-(void)resize;


@end
