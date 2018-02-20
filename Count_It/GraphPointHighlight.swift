//
//  GraphPointHighlight.swift
//  Count_It
//
//  Created by Michael LaRandeau on 9/13/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class GraphPointHighlight: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.black.setStroke()
        let outline = NSBezierPath()
        outline.lineWidth = 2
        outline.appendOval(in: NSRect(x: outline.lineWidth * 0.5, y: outline.lineWidth * 0.5, width: bounds.size.width - outline.lineWidth, height: bounds.size.height - outline.lineWidth))
        
        outline.stroke()
    }
    
}
