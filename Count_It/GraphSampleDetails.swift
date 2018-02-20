//
//  GraphSampleDetails.swift
//  Count_It
//
//  Created by Michael LaRandeau on 9/12/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class GraphSampleDetails: NSView {
    
    weak var popover: NSPopover?
    var sample: Sample?
    let locale = NSLocale.autoupdatingCurrent
    let numFormatter = NumberFormatter()
    let labelFont = NSFont.systemFont(ofSize: 12)
    let labelColor = NSColor.black
    let frameLabelAttributes: [NSAttributedStringKey:AnyObject]
    
    var frameRateLabel: NSString?
    var frameRateLabelSize: NSSize?
    
    convenience init(aPopover: NSPopover) {
        let frame = NSRect(x: 0, y: 0, width: 0, height: 0)
        self.init(frame: frame)
        popover = aPopover
    }
    
    override init(frame frameRect: NSRect) {
        frameLabelAttributes = [NSAttributedStringKey.font:labelFont,NSAttributedStringKey.foregroundColor:labelColor]
        
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        frameLabelAttributes = [NSAttributedStringKey.font:labelFont,NSAttributedStringKey.foregroundColor:labelColor]
        
        super.init(coder: coder)
    }
    
    override func viewWillDraw() {
        if sample != nil && popover != nil {
            setupNumFormatter()
            
            frameRateLabel = numFormatter.string(from: NSNumber(value: sample!.frameRate))! as NSString?
            frameRateLabelSize = frameRateLabel!.size(withAttributes: frameLabelAttributes)
            
            var frameWidth = frameRateLabelSize!.width
            if frameWidth < 20 { frameWidth = 20 }
            var frameHeight = frameRateLabelSize!.height
            if frameHeight < 10 { frameHeight = 10 }
            let frameSize = NSSize(width: frameWidth + 20, height: frameHeight + 10)
            setFrameSize(frameSize)
            popover!.contentSize = frameSize
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if frameRateLabel != nil && popover!.isShown {
            frameRateLabel!.draw(at: NSPoint(x: bounds.midX - frameRateLabelSize!.width * 0.5, y: bounds.midY - frameRateLabelSize!.height * 0.5), withAttributes: frameLabelAttributes)
        }
    }
    
    func setupNumFormatter() {
        let precision = UserDefaults.standard.integer(forKey: "MLDecimalPrecision")
        numFormatter.locale = locale
        numFormatter.numberStyle = NumberFormatter.Style.decimal
        numFormatter.minimumFractionDigits = precision
        numFormatter.maximumFractionDigits = precision
    }
}
