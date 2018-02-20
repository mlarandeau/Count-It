//
//  GraphSysInfoDetails.swift
//  Count_It
//
//  Created by Michael LaRandeau on 10/17/15.
//  Copyright © 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class GraphSysInfoDetails: NSView {
    
    weak var popover: NSPopover?
    var systemInformation: SystemInformation?
    let labelFont = NSFont.systemFont(ofSize: 12)
    let labelColor = NSColor.black
    let labelAttributes: [NSAttributedStringKey:AnyObject]
    var allLabels: [(String,String)] = []
    let padding: CGFloat = 10
    let columnSpacer: CGFloat = 10
    var rightColumnLeftEdge: CGFloat = 0
    var shouldFillBackground: Bool = false
    
    override var isFlipped: Bool {
        get {
            return true
        }
    }
    
    convenience init(aPopover: NSPopover) {
        let frame = NSRect(x: 10, y: 10, width: 10, height: 10)
        self.init(frame: frame)
        popover = aPopover
    }
    
    override init(frame frameRect: NSRect) {
        labelAttributes = [NSAttributedStringKey.font:labelFont,NSAttributedStringKey.foregroundColor:labelColor]
        
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        labelAttributes = [NSAttributedStringKey.font:labelFont,NSAttributedStringKey.foregroundColor:labelColor]
        
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if shouldFillBackground {
            NSColor(calibratedRed: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0).set()
            bounds.fill()
        }
        
        var yPos: CGFloat = padding
        for label in allLabels {
            let leftLabel = label.0 as NSString
            let rightLabel = label.1 as NSString
            
            leftLabel.draw(at: NSPoint(x: padding, y: yPos), withAttributes: labelAttributes)
            rightLabel.draw(at: NSPoint(x: padding + rightColumnLeftEdge, y: yPos), withAttributes: labelAttributes)
            yPos += leftLabel.size(withAttributes: labelAttributes).height
        }
    }
    
    override func viewWillDraw() {
        determineFrameSize()
    }
    
    func determineFrameSize() {
        if systemInformation != nil {
            makeLabels()
            
            var totalHeight: CGFloat = 0
            //Left Column
            var maxLeftColumn: CGFloat = 0
            for label in allLabels {
                let leftSize = (label.0 as NSString).size(withAttributes: labelAttributes)
                if leftSize.width > maxLeftColumn { maxLeftColumn = leftSize.width }
                totalHeight += leftSize.height
            }
            
            //Right Column
            var maxRightColumn: CGFloat = 0
            for label in allLabels {
                let rightSize = (label.1 as NSString).size(withAttributes: labelAttributes)
                if rightSize.width > maxRightColumn { maxRightColumn = rightSize.width }
            }
            
            rightColumnLeftEdge = maxLeftColumn + columnSpacer
            
            setFrameSize(NSSize(width: maxLeftColumn + maxRightColumn + columnSpacer + (padding * 2), height: totalHeight + (padding * 2)))
            if popover != nil { popover!.contentSize = frame.size }
        }
    }
    
    func makeLabels() {
        allLabels.removeAll()
        
        let computerNameToUse = systemInformation!.computerType != "" ? systemInformation!.computerType : systemInformation!.computerName
        
        allLabels += [("Computer:","\(computerNameToUse)")]
        
        if systemInformation!.computerModel != "" {
            allLabels += [("Model:","\(systemInformation!.computerModel)")]
        }
        
        allLabels += [("OS Version:","\(systemInformation!.version)"),
                        ("Processor:","\(systemInformation!.processorName)"),
                        ("Speed:","\(systemInformation!.processorSpeed)"),
                        ("Cores:","\(systemInformation!.processorCores)"),
                        ("RAM:","\(systemInformation!.ram)")]
        if systemInformation!.gpuName != "" { allLabels += [("GPU:","\(systemInformation!.gpuName)")] }
        if systemInformation!.gpuVRAM != "" { allLabels += [("GPU VRAM:","\(systemInformation!.gpuVRAM)")] }
    }
    
}
