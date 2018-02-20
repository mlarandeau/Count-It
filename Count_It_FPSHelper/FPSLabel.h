//
//  FPSLabel.h
//  Count_It
//
//  Created by Michael LaRandeau on 7/24/16.
//  Copyright © 2016 Michael LaRandeau. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FPSLabel : NSView

@property NSString *text;
@property NSColor *fontColor;
@property NSFont *font;

- (void) updateFontWithName:(NSString *)fontName;
- (void) updateFontWithSize:(double)fontSize;
- (NSSize) getSizeWithDigits:(int)digits precision:(int)precision;

@end
