//
//  FPSDisplay.m
//  Count_It
//
//  Created by Michael LaRandeau on 2/18/16.
//  Copyright © 2016 Michael LaRandeau. All rights reserved.
//

#import "FPSDisplay.h"
#import "FPSLabel.h"
#import "FPSRecordButton.h"

@implementation FPSDisplay

@synthesize backgroundColor = _backgroundColor;
@synthesize useRoundedCorners = _useRoundedCorners;
@synthesize digits = _digits;
@synthesize precision = _precision;

- (id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _backgroundColor = [NSColor blackColor];
        _useRoundedCorners = NO;
        _precision = 0;
        _digits = 0;
        
        //[self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        
        self.label = [[FPSLabel alloc] initWithFrame:frameRect];
        self.record = [[FPSRecordButton alloc] initWithFrame:frameRect];
        
        [self addSubview:self.label];
        [self addSubview:self.record];
        
        return self;
    }
    else {
        return nil;
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [self.backgroundColor set];
    if (self.useRoundedCorners) {
        CGFloat roundRadius = self.bounds.size.height * 0.1;
        NSBezierPath *background = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:roundRadius yRadius:roundRadius];
        [background fill];
    }
    else {
        NSRectFill(self.bounds);
    }
}

- (NSSize)getCountSize:(CGFloat)fontSize precision:(int)precision {
    NSSize newSize = [self.label getSizeWithDigits:3 precision:precision];
    
    return newSize;
}

- (void) resize {
    NSSize labelSize = [self.label getSizeWithDigits:self.digits precision:self.precision];
    NSSize recordSize;
    if (self.record.hidden) {
        recordSize = NSMakeSize(0, 0);
    }
    else {
        recordSize = NSMakeSize(labelSize.height * 0.9, labelSize.height * 0.9);
    }
    
    float xPadding = (labelSize.width + recordSize.width) * 0.1 * 0.5;
    float yPadding = labelSize.height * 0.1 * 0.5;
    
    CGFloat xPaddingMultiplier = self.record.hidden ? 2 : 3;
    NSSize displaySize = NSMakeSize(labelSize.width + recordSize.width + (xPadding * xPaddingMultiplier), labelSize.height + (yPadding * 2));
    [self setFrameSize:displaySize];
    
    NSRect labelFrame = NSMakeRect(xPadding, yPadding, labelSize.width, labelSize.height);
    [self.label setFrame:labelFrame];
    
    if (!self.record.hidden) {
        NSRect recordFrame = NSMakeRect(labelFrame.origin.x + labelFrame.size.width + xPadding, displaySize.height * 0.5 - recordSize.height * 0.5, recordSize.width, recordSize.height);
        [self.record setFrame:recordFrame];
    }
}

/*** backgroundColor ***/
- (NSColor *) backgroundColor {
    return _backgroundColor;
}

- (void) setBackgroundColor:(NSColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    self.needsDisplay = YES;
}

/*** useRoundedCorners ***/
- (BOOL) useRoundedCorners {
    return _useRoundedCorners;
}

- (void) setUseRoundedCorners:(BOOL)useRoundedCorners {
    _useRoundedCorners = useRoundedCorners;
    self.needsDisplay = YES;
}

/*** count ***/
- (NSString *) count {
    return self.label.text;
}

- (void) setCount:(NSString *)count {
    self.label.text = count;
}

/*** fontColor ***/
- (NSColor *) fontColor {
    return self.label.fontColor;
}

- (void) setFontColor:(NSColor *)fontColor {
    self.label.fontColor = fontColor;
}

/*** font ***/
- (NSFont *) font {
    return self.label.font;
}

- (void) setFont:(NSFont *)font {
    self.label.font = font;
    [self resize];
}

- (void) updateFontWithName:(NSString *)fontName {
    [self.label updateFontWithName:fontName];
    [self resize];
}

- (void) updateFontWithSize:(double)fontSize {
    [self.label updateFontWithSize:fontSize];
    [self resize];
}

/*** precision ***/
- (int) precision {
    return _precision;
}

- (void) setPrecision:(int)precision {
    NSArray *countParts = [self.count componentsSeparatedByString:@"."];
    NSString *digits;
    NSString *decimals;
    if (countParts.count == 0) {
        digits = @"0";
    }
    else if (countParts.count == 1) {
        digits = countParts[0];
        decimals = @"";
    }
    else if (countParts.count >= 2) {
        digits = countParts[0];
        decimals = countParts[1];
    }
    
    if (precision == 0) {
        self.count = digits;
    }
    else {
        NSString *newText = @"";
        if (precision < decimals.length) {
            NSString *keepDecimals = @"";
            for (int i=0;i<precision;i++) {
                NSString *decimal = [decimals substringWithRange:NSMakeRange(i, 1)];
                keepDecimals = [keepDecimals stringByAppendingString:decimal];
            }
            newText = [digits stringByAppendingString:@"."];
            newText = [newText stringByAppendingString:keepDecimals];
        }
        else {
            if (self.precision == 0) { newText = [self.count stringByAppendingString:@"."]; }
            else { newText = self.count; }
            for (NSUInteger i=decimals.length;i<precision;i++) {
                newText = [newText stringByAppendingString:@"0"];
            }
        }
        self.count = newText;
    }
    
    _precision = precision;
    
    [self resize];
}

/*** digits ***/
- (int) digits {
    return _digits;
}

- (void) setDigits:(int)digits {
    _digits = digits;
    [self resize];
}

/*** showRecordingButton ***/
- (BOOL) showRecordingButton {
    return !self.record.hidden;
}

- (void) setShowRecordingButton:(BOOL)showRecordingButton {
    self.record.hidden = !showRecordingButton;
    [self resize];
}

@end






