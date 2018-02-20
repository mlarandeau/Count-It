//
//  AddGraphicsSheet.swift
//  Count_It
//
//  Created by Michael LaRandeau on 10/17/15.
//  Copyright © 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class AddGraphicsSheet: NSWindowController {
    
    @IBOutlet var graphicsSetting: NSTextField!
    var graphHeader: GraphHeaderView?

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func setGraphicsLevel(sender: NSButton) {
        if graphHeader != nil && graphHeader!.parent.session != nil {
            if graphicsSetting.stringValue != "" {
                graphHeader!.graphics.title = graphicsSetting.stringValue
                graphHeader!.parent.session!.graphicsSetting = graphicsSetting.stringValue
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
