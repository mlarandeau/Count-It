//
//  AddResolutionSheet.swift
//  Count_It
//
//  Created by Michael LaRandeau on 10/17/15.
//  Copyright © 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class AddResolutionSheet: NSWindowController {
    
    var graphHeader: GraphHeaderView?
    @IBOutlet var setWidth: NSTextField!
    @IBOutlet var setHeight: NSTextField!
    @IBOutlet var setNewResolution: NSButton!

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func setResolution(sender: NSButton) {
        if graphHeader != nil && graphHeader!.parent.session != nil {
            let width = Int(setWidth.intValue)
            let height = Int(setHeight.intValue)
            if width > 0 && height > 0 {
                let newResolution = Resolution(width: Int(setWidth.intValue), height: Int(setHeight.intValue))
                graphHeader!.parent.session!.resolution = newResolution
                graphHeader!.resolution.title = newResolution.text
            }
        }
        closeSheet(sender: sender)
    }
    
    @IBAction func closeSheet(sender: NSButton) {
        if window!.sheetParent != nil {
            window!.sheetParent!.endSheet(window!)
        }
    }
}
