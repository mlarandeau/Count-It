//
//  FPSWindowController.m
//  Count_It
//
//  Created by Michael LaRandeau on 4/25/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

#import "FPSWindowController.h"
#import "AppDelegate.h"

@interface FPSWindowController ()

@end

@implementation FPSWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    AppDelegate *app = (AppDelegate *)[NSApp delegate];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults addSuiteNamed:app.parentName];
    
    
    /*************************************************
     //Initialize Window Properties
     ************************************************/
    [[self window] setStyleMask:NSBorderlessWindowMask];
    [[self window] setLevel:kCGMaximumWindowLevel];
    [[self window] setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorTransient|NSWindowCollectionBehaviorFullScreenAuxiliary];
    [[self window] setHasShadow:NO];
    
    [[self window] setOpaque:NO];
    
    [[self window] setBackgroundColor:[NSColor clearColor]];
    
    [[self window] setMovableByWindowBackground:NO];
    
    //[self.window.contentView setAutoresizesSubviews:YES];
    
    /*************************************************
     Add Primary View
     ************************************************/
    self.fps = [[FPSDisplay alloc] initWithFrame:self.window.frame];
    [[self window] setContentView:self.fps];
    
    double fontSize = (double)[defaults integerForKey:@"MLFPSFontSize"];
    if (fontSize == 0) { fontSize = 25; }
    NSString *fontName = [defaults stringForKey:@"MLFPSFont"];
    NSFont *font;
    if (fontName != nil) { font = [NSFont fontWithName:fontName size:fontSize]; }
    if (font == nil) { font = [NSFont systemFontOfSize:fontSize]; }
    if (font != nil) { self.fps.font = font; }
    
    if ([defaults boolForKey:@"MLFPSUseRoundedCorners"]) {
        self.fps.useRoundedCorners = YES;
    }
    
    self.fps.digits = 3;
    
    self.fps.precision = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"MLDecimalPrecision"];
    
    /*************************************************
     Set Defaults
     ************************************************/
    NSData *backgroundColorData = [defaults dataForKey:@"MLFPSBackgroundColor"];
    NSColor *backgroundColor;
    if (backgroundColorData != nil) { backgroundColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:backgroundColorData]; }
    if (backgroundColor == nil) { backgroundColor = [NSColor blackColor]; }
    
    NSData *fontColorData = [defaults dataForKey:@"MLFPSFontColor"];
    NSColor *fontColor;
    if (fontColorData != nil) { fontColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:fontColorData]; }
    if (fontColor == nil) { fontColor = [NSColor whiteColor]; }
    
    NSData *recordingColorData = [defaults dataForKey:@"MLRecordingBackgroundColor"];
    NSColor *recordingColor;
    if (recordingColorData != nil) { recordingColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:recordingColorData]; }
    if (recordingColor == nil) { recordingColor = [NSColor redColor]; }
    
    NSData *recordingFontData = [defaults dataForKey:@"MLRecordingFontColor"];
    NSColor *recordingFontColor;
    if (recordingFontData != nil) { recordingFontColor = (NSColor *)[NSUnarchiver unarchiveObjectWithData:recordingFontData]; }
    if (recordingFontColor == nil) { recordingFontColor = [NSColor whiteColor]; }
    
    if ([defaults boolForKey:@"MLRecordingAutoStart"]) {
        self.fps.record.isRecording = YES;
    }
    else {
        self.fps.record.isRecording = NO;
    }
    
    if ([defaults boolForKey:@"MLRecordingShouldChangeColor"]) {
        [self updateBackgroundColor:recordingColor];
        [self updateFontColor:recordingFontColor];
    }
    else {
        [self updateBackgroundColor:backgroundColor];
        [self updateFontColor:fontColor];
    }
    
    self.fps.record.fillColor = recordingColor;
    self.fps.record.borderColor = recordingFontColor;
    
    self.screenPosition = (int)[defaults integerForKey:@"MLFPSScreenPosition"];
    
    self.fps.showRecordingButton = [defaults boolForKey:@"MLRecordingShowToggleButton"];
    
    [self updateSize];
}

-(void)updateFrameRate:(NSString *)frameRate {
    self.fps.count = frameRate;
    [self reposition];
}

-(void)updateBackgroundColor:(NSColor *)color {
    self.fps.backgroundColor = color;
}

-(void)updateRecordFillColor:(NSColor *)color {
    self.fps.record.fillColor = color;
}

-(void)updateFontColor:(NSColor *)color {
    self.fps.fontColor = color;
}

-(void)updateRecordBorderColor:(NSColor *)color {
    self.fps.record.borderColor = color;
}

-(void)updateFontName:(NSString *)fontName {
    [self.fps updateFontWithName:fontName];
    [self updateSize];
}

-(void)updateFontSize:(double)fontSize {
    [self.fps updateFontWithSize:fontSize];
    [self updateSize];
}

-(void)updatePrecision:(int)precision {
    self.fps.precision = precision;
    [self updateSize];
}

-(void)updateRoundedCorners:(BOOL)shouldUseRoundedCorners {
    self.fps.useRoundedCorners = shouldUseRoundedCorners;
}

-(void)updateSize {
    NSSize windowSize = self.fps.frame.size;
    NSPoint position = [self getPosition:windowSize];
    NSRect newFrame = NSMakeRect(position.x, position.y, windowSize.width, windowSize.height);
    [self.window setFrame:newFrame display:YES animate:YES];
    [self showWindow:self];
}

-(void)toggleIsRecording:(BOOL)shouldRecord {
    self.fps.record.isRecording = shouldRecord;
}

-(void)toggleShowRecordingButton:(BOOL)shouldShow {
    self.fps.showRecordingButton = shouldShow;
    [self updateSize];
}

-(NSPoint)getPosition:(NSSize)size {
    NSScreen *screen = [NSScreen mainScreen];
    CGFloat screenWidth = screen.frame.size.width;
    CGFloat screenHeight = screen.frame.size.height;
    
    CGFloat left = 0;
    CGFloat bottom = 0;
    
    if (self.screenPosition < 0) { self.screenPosition = 0; }
    else if (self.screenPosition > 8) {self.screenPosition = 8; }
    
    if (self.screenPosition == 0) {
        left = 0;
        bottom = screenHeight - size.height;
    }
    else if (self.screenPosition == 1) {
        left = (screenWidth * 0.5) - (size.width * 0.5);
        bottom = screenHeight - size.height;
    }
    else if (self.screenPosition == 2) {
        left = screenWidth - size.width;
        bottom = screenHeight - size.height;
    }
    else if (self.screenPosition == 3) {
        left = 0;
        bottom = (screenHeight * 0.5) - (size.height * 0.5);
    }
    else if (self.screenPosition == 4) {
        left = (screenWidth * 0.5) - (size.width * 0.5);
        bottom = (screenHeight * 0.5) - (size.height * 0.5);
    }
    else if (self.screenPosition == 5) {
        left = screenWidth - size.width;
        bottom = (screenHeight * 0.5) - (size.height * 0.5);
    }
    else if (self.screenPosition == 6) {
        left = 0;
        bottom = 0;
    }
    else if (self.screenPosition == 7) {
        left = (screenWidth * 0.5) - (size.width * 0.5);
        bottom = 0;
    }
    else if (self.screenPosition == 8) {
        left = (screenWidth - size.width);
        bottom = 0;
    }
    return NSMakePoint(left, bottom);
}

-(void)reposition {
    NSPoint position = [self getPosition:self.window.frame.size];
    [self.window setFrame:NSMakeRect(position.x, position.y, self.window.frame.size.width, self.window.frame.size.height) display:YES animate:YES];
}


@end








