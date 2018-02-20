//
//  AttachToProcessSheet.swift
//  Count_It
//
//  Created by Michael LaRandeau on 7/23/17.
//  Copyright © 2017 Michael LaRandeau. All rights reserved.
//

import Cocoa

class AttachToProcessSheet: NSWindowController {
    
    @IBOutlet private var pid: NSTextField!
    private(set) var game: Game?

    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func attach(sender: NSButton) {
        guard let app = NSRunningApplication(processIdentifier: pid.intValue),
            let appURL = app.bundleURL ?? app.executableURL,
            let matchedGame = Game(url: appURL as NSURL) else {
                Supportive.alert(message: "The PID you entered is either invalid or does not reference a running application.")
                return
        }
        self.game = matchedGame
        closeSheet(withResponse: NSApplication.ModalResponse.OK)
    }
    
    @IBAction func cancel(sender: NSButton) {
        closeSheet(withResponse: NSApplication.ModalResponse.cancel)
    }
    
    private func closeSheet(withResponse response: NSApplication.ModalResponse) {
        guard let win = window, let parent = win.sheetParent else { return }
        parent.endSheet(win, returnCode: response)
    }
    
}
