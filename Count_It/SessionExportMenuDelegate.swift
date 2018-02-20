//
//  SessionExportMenuDelegate.swift
//  Count_It
//
//  Created by Michael LaRandeau on 10/11/15.
//  Copyright © 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class SessionExportMenuDelegate: NSObject, NSMenuDelegate {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        let selected = app!.mainWindow.sessionList.selectedSession
        let clicked = app!.mainWindow.sessionList.clickedSession
        
        let enabled = selected == clicked ? true : false
        
        menu.item(withTag: 1)!.isEnabled = enabled
        menu.item(withTag: 2)!.isEnabled = enabled
    }

}
