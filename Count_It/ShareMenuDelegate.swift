//
//  ShareMenuDelegate.swift
//  Count_It
//
//  Created by Michael LaRandeau on 11/7/15.
//  Copyright © 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class ShareMenuDelegate: NSObject, NSMenuDelegate {
    @IBOutlet weak var app: AppDelegate!
    
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        let refImage = NSImage()
        let allServices = NSSharingService.sharingServices(forItems: [refImage])
        for service in allServices {
            let newItem = NSMenuItem(title: service.title, action: #selector(MainMenuController.share(sender:)), keyEquivalent: "")
            newItem.image = service.image
            newItem.representedObject = service
            newItem.target = app!.menu!
            menu.addItem(newItem)
        }
    }
}
