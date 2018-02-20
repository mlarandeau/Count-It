//
//  FPSRecordButton.m
//  Count_It
//
//  Created by Michael LaRandeau on 7/24/16.
//  Copyright © 2016 Michael LaRandeau. All rights reserved.
//

#import "FPSRecordButton.h"

@implementation FPSRecordButton

@synthesize fillColor = _fillColor;
@synthesize borderColor = _borderColor;
@synthesize isRecording = _isRecording;
@synthesize isHighlighted = _isHighlighted;
@synthesize isPressed = _isPressed;

-(id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.fillColor = [NSColor redColor];
        self.borderColor = [NSColor whiteColor];
        
        _isRecording = NO;
        
        NSTrackingArea *fullTracker = [[NSTrackingArea alloc] initWithRect:self.bounds options:NSTrackingActiveAlways|NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
        [self addTrackingArea:fullTracker];
        
        [self sendActionOn:NSLeftMouseUpMask];
        
        return self;
    }
    else {
        return nil;
    }
}

-(void)drawRect:(NSRect)dirtyRect {
    //[super drawRect:dirtyRect];
    
    [self.fillColor setFill];
    [self.borderColor setStroke];
    
    CGFloat innerOffset = self.bounds.size.width * 0.1;
    NSRect innerRect = NSMakeRect(innerOffset, innerOffset, self.bounds.size.width - (innerOffset * 2), self.bounds.size.height - (innerOffset * 2));
    
    NSBezierPath * outerPath;
    NSBezierPath *innerPath;
    
    if (self.isRecording) {
        CGFloat cornerRadius = self.bounds.size.width * 0.1;
        
        outerPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:cornerRadius yRadius:cornerRadius];
        innerPath = [NSBezierPath bezierPathWithRoundedRect:innerRect xRadius:cornerRadius yRadius:cornerRadius];
    }
    else {
        outerPath = [NSBezierPath bezierPathWithOvalInRect:self.bounds];
        innerPath = [NSBezierPath bezierPathWithOvalInRect:innerRect];
    }
    
    CGFloat shadowLevel = 0.15;
    
    if (self.isPressed) { [[self.borderColor shadowWithLevel:shadowLevel] setFill]; }
    else { [self.borderColor setFill]; }
    [outerPath fill];
    
    if (self.isPressed) { [[self.fillColor shadowWithLevel:shadowLevel] setFill]; }
    else {
        [self.fillColor setFill];
        if (self.isHighlighted) {
            NSShadow *shadow = [[NSShadow alloc] init];
            shadow.shadowOffset = NSMakeSize(0, 0);
            shadow.shadowBlurRadius = innerOffset;
            shadow.shadowColor = [NSColor shadowColor];
            [shadow set];
        }
    }
    [innerPath fill];
}

-(void)updateTrackingAreas {
    [super updateTrackingAreas];
    
    for (NSTrackingArea *area in self.trackingAreas) {
        if (area.rect.size.width != self.bounds.size.width && area.rect.size.height != self.bounds.size.height) {
            [self removeTrackingArea:area];
            NSTrackingArea *newArea = [[NSTrackingArea alloc] initWithRect:self.bounds options:area.options owner:area.owner userInfo:area.userInfo];
            [self addTrackingArea:newArea];
        }
    }
}

-(void)mouseDown:(NSEvent *)theEvent {
    self.isPressed = YES;
    [super mouseDown:theEvent];
}

-(void)mouseUp:(NSEvent *)theEvent {
    self.isPressed = NO;
    if (self.action != nil && self.target != nil && [self.target respondsToSelector:self.action]) {
        [self sendAction:self.action to:self.target];
    }
    self.needsDisplay = YES;
    [super mouseUp:theEvent];
}

-(void)mouseEntered:(NSEvent *)theEvent {
    self.isHighlighted = YES;
}

-(void)mouseExited:(NSEvent *)theEvent {
    self.isHighlighted = NO;
}

/*** fillColor ***/
-(NSColor *)fillColor {
    return _fillColor;
}

-(void)setFillColor:(NSColor *)fillColor {
    _fillColor = fillColor;
    self.needsDisplay = YES;
}

/*** borderColor ***/
-(NSColor *)borderColor {
    return _borderColor;
}

-(void)setBorderColor:(NSColor *)borderColor {
    _borderColor = borderColor;
    self.needsDisplay = YES;
}

/*** isRecording ***/
-(BOOL)isRecording {
    return _isRecording;
}

-(void)setIsRecording:(BOOL)isRecording {
    _isRecording = isRecording;
    self.needsDisplay = YES;
}

/*** isHighlighted **/
-(BOOL)isHighlighted {
    return _isHighlighted;
}

-(void)setIsHighlighted:(BOOL)isHighlighted {
    _isHighlighted = isHighlighted;
    self.needsDisplay = YES;
}

/*** isPressed ***/
-(BOOL)isPressed {
    return _isPressed;
}

-(void)setIsPressed:(BOOL)isPressed {
    _isPressed = isPressed;
    self.needsDisplay = YES;
}

@end
