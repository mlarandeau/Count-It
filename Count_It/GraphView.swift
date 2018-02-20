//
//  GraphView.swift
//  Count_It
//
//  Created by Michael LaRandeau on 8/12/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class GraphView: NSVisualEffectView {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    var session: Session?
    @IBOutlet var header: GraphHeaderView!
    @IBOutlet var content: GraphContentView!
    let popover = NSPopover()
    
    let headerDateFormatter = DateFormatter()
    let headerTimeFormatter = DateFormatter()
    let numFormatter = NumberFormatter()
    let locale = NSLocale.autoupdatingCurrent
    var holdDraw: Bool = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        popover.behavior = NSPopover.Behavior.transient
        let popoverController = NSViewController()
        popoverController.view = GraphSampleDetails(aPopover: popover)
        popover.contentViewController = popoverController
        
        headerDateFormatter.locale = locale
        headerDateFormatter.dateStyle = DateFormatter.Style.short
        headerDateFormatter.timeStyle = DateFormatter.Style.none
        headerTimeFormatter.dateStyle = DateFormatter.Style.none
        headerTimeFormatter.timeStyle = DateFormatter.Style.medium
        
        numFormatter.locale = locale
        numFormatter.numberStyle = NumberFormatter.Style.decimal
        setNumberPrecision()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func setNumberPrecision() {
        let precision = UserDefaults.standard.integer(forKey: "MLDecimalPrecision")
        numFormatter.minimumFractionDigits = precision
        numFormatter.maximumFractionDigits = precision
    }
}






