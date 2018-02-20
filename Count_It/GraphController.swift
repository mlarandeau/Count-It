//
//  GraphController.swift
//  Count_It
//
//  Created by Michael LaRandeau on 8/23/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class GraphController: NSViewController {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    
    func assignNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(GraphController.shouldHoldDraw(notification:)), name: NSNotification.Name(rawValue: "NSWindowWillEnterFullScreenNotification"), object: app!.mainWindow.window!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GraphController.shouldHoldDraw(notification:)), name: NSNotification.Name(rawValue: "NSWindowWillExitFullScreenNotification"), object: app!.mainWindow.window!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GraphController.shouldNotHoldDraw(notification:)), name: NSNotification.Name(rawValue: "NSWindowDidEnterFullScreenNotification"), object: app!.mainWindow.window!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(GraphController.shouldNotHoldDraw(notification:)), name: NSNotification.Name(rawValue: "NSWindowDidExitFullScreenNotification"), object: app!.mainWindow.window!)
    }
    
    @objc func shouldHoldDraw(notification: NSNotification) {
        if let theView = view as? GraphView {
            if theView.session != nil && theView.session!.samples.count > 1000 {
                theView.holdDraw = true
            }
        }
    }
    
    @objc func shouldNotHoldDraw(notification: NSNotification) {
        if let theView = view as? GraphView {
            theView.holdDraw = false
            theView.needsDisplay = true
        }
    }
}
