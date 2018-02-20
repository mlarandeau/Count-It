//
//  SessionListCell.swift
//  Count_It
//
//  Created by Michael LaRandeau on 8/12/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class SessionListCell: NSTableCellView {
    
    @IBOutlet var recordingTitle: NSTextField!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.gridColor.setStroke()
        
        let border = NSBezierPath()
        border.move(to: NSPoint(x: 0, y: 0))
        border.line(to: NSPoint(x: bounds.size.width, y: 0))
        
        border.stroke()
    }
}
