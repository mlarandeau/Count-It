//
//  SplitView.swift
//  Count_It
//
//  Created by Michael LaRandeau on 8/30/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class SplitView: NSSplitView {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override var dividerThickness: CGFloat {
        get {
            if (subviews[1] ).isHidden && (subviews[2] ).isHidden {
                return 0.0
            }
            else { return 1.0 }
        }
    }
}
