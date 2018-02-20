//
//  RootView.swift
//  Count_It
//
//  Created by Michael LaRandeau on 2/14/16.
//  Copyright © 2016 Michael LaRandeau. All rights reserved.
//

import Cocoa

class RootView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor(calibratedRed: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0).set()
        dirtyRect.fill()
    }
    
}
