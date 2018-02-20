//
//  FPSLabel.m
//  Count_It
//
//  Created by Michael LaRandeau on 7/24/16.
//  Copyright © 2016 Michael LaRandeau. All rights reserved.
//

#import "FPSLabel.h"

@implementation FPSLabel

@synthesize text = _text;
@synthesize font = _font;
@synthesize fontColor = _fontColor;

-(id)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        self.text = @"0";
        self.fontColor = [NSColor whiteColor];
        self.font = [NSFont systemFontOfSize:25];
        
        //[self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        
        return self;
    }
    else {
        return nil;
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [self.fontColor set];
    NSDictionary *countAttributes = @{ NSFontAttributeName : self.font,
                                       NSForegroundColorAttributeName : self.fontColor };
    NSSize countSize = [self.text sizeWithAttributes:countAttributes];
    CGFloat countXPos = self.frame.size.width * 0.5 - countSize.width * 0.5;
    CGFloat countYPos = self.frame.size.height * 0.5 - countSize.height * 0.5;
    
    [self.text drawAtPoint:NSMakePoint(countXPos, countYPos) withAttributes:countAttributes];
}

- (NSSize) getSizeWithDigits:(int)digits precision:(int)precision {
    NSString *refCount = @"";
    for (int i=0;i<digits;i++) {
        refCount = [refCount stringByAppendingString:@"0"];
    }
    if (precision > 0) {
        refCount = [refCount stringByAppendingString:@"."];
        for (int i=0;i<precision;i++) {
            refCount = [refCount stringByAppendingString:@"0"];
        }
    }
    
    NSDictionary *textAttributes = @{ NSFontAttributeName : self.font,
                                      NSForegroundColorAttributeName : self.fontColor };
    return [refCount sizeWithAttributes:textAttributes];
}


/*** text ***/
- (NSString *) text {
    return _text;
}

- (void) setText: (NSString *) text {
    _text = text;
    self.needsDisplay = YES;
}

/*** fontColor ***/
- (NSColor *) fontColor {
    return _fontColor;
}

- (void) setFontColor:(NSColor *)fontColor {
    _fontColor = fontColor;
    self.needsDisplay = YES;
}

/*** font ***/
- (NSFont *) font {
    return _font;
}

- (void) setFont:(NSFont *)font {
    _font = font;
    self.needsDisplay = YES;
}

- (void) updateFontWithName:(NSString *)fontName {
    NSFont *newFont = [NSFont fontWithName:fontName size:self.font.pointSize];
    if (newFont != nil) {
        self.font = newFont;
    }
}

- (void) updateFontWithSize:(double)fontSize {
    NSFont *newFont = [NSFont fontWithName:self.font.fontName size:fontSize];
    if (newFont != nil) {
        self.font = newFont;
    }
}


@end
