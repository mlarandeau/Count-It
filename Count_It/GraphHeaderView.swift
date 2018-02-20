//
//  GraphHeaderView.swift
//  Count_It
//
//  Created by Michael LaRandeau on 8/22/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class GraphHeaderView: NSView {

    weak var app = NSApplication.shared.delegate as? AppDelegate
    @IBOutlet weak var parent: GraphView!
    @IBOutlet var resolutionLabel: NSTextField!
    @IBOutlet var resolution: NSPopUpButton!
    @IBOutlet var graphics: NSPopUpButton!
    @IBOutlet var graphicsLabel: NSTextField!
    @IBOutlet var viewSysInfo: NSButton!
    var allResolutions: [Resolution]?
    let popover = NSPopover()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        popover.behavior = NSPopover.Behavior.transient
        let popoverController = NSViewController()
        popoverController.view = GraphSysInfoDetails(aPopover: popover)
        popover.contentViewController = popoverController
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let context = NSGraphicsContext.current {
            /*NSColor(calibratedRed: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0).set()
            NSRectFill(bounds)*/
            
            if parent.session != nil {
                _ = drawHeader(context: context)
            }
        }
    }
    
    override func viewWillDraw() {
        if parent.session != nil {
            resolution.isHidden = false
            resolutionLabel.isHidden = false
            graphics.isHidden = false
            graphicsLabel.isHidden = false
            if parent.session!.systemInformation != nil { viewSysInfo.isTransparent = false }
            else { viewSysInfo.isTransparent = true }
            
            //Resolution
            if let res = parent.session?.resolution {
                resolution.title = res.text
                resolution.menu!.item(at: 0)!.isEnabled = true
            }
            else {
                resolution.title = "Set..."
                resolution.menu!.item(at: 0)!.isEnabled = false
            }
            
            //Graphics
            if let gSettings = parent.session?.graphicsSetting {
                graphics.title = gSettings
                graphics.menu!.item(at: 0)!.isEnabled = true
            }
            else {
                graphics.title = "Set..."
                graphics.menu!.item(at: 0)!.isEnabled = false
            }
        }
        else {
            resolution.isHidden = true
            resolutionLabel.isHidden = true
            graphics.isHidden = true
            graphicsLabel.isHidden = true
            viewSysInfo.isTransparent = true
        }
    }
    
    func drawHeader(context: NSGraphicsContext)->CGFloat {
        var bottomEdge = bounds.height
        let fontColor = NSColor.black
        let topOffset: CGFloat = 10
        let leftOffset: CGFloat = 15
        let lineOffset: CGFloat = 2
        
        //Game Name
        let gameNameAttributes: [NSAttributedStringKey:AnyObject] = [NSAttributedStringKey.font:NSFont.boldSystemFont(ofSize: 16),
            NSAttributedStringKey.foregroundColor:fontColor]
        let sessionGame = app!.mainWindow.table.selectedGame!
        let gameName: NSString = sessionGame.displayName != nil ? sessionGame.displayName! as NSString : sessionGame.name as NSString
        //let gameSize = gameName.sizeWithAttributes(gameNameAttributes)
        //let gameNameXPos = bounds.midX - gameSize.width * 0.5
        let gameNameXPos = leftOffset
        let gameNameYPos = bounds.height - topOffset - gameName.size(withAttributes: gameNameAttributes).height
        gameName.draw(at: NSPoint(x: gameNameXPos, y: gameNameYPos), withAttributes: gameNameAttributes)
        
        bottomEdge = gameNameYPos
        
        //Recording Title
        let title: NSString? = parent.session!.title != nil ? NSString(string: parent.session!.title!) : nil
        var titleYPos: CGFloat = gameNameYPos
        if title != nil {
            let titleAttributes: [NSAttributedStringKey:AnyObject] = [NSAttributedStringKey.font:NSFont.systemFont(ofSize: 14),
                NSAttributedStringKey.foregroundColor:fontColor]
            let titleSize = title!.size(withAttributes: titleAttributes)
            //let titleXPos = bounds.midX - titleSize.width * 0.5
            let titleXPos = leftOffset
            titleYPos = gameNameYPos - lineOffset - titleSize.height
            title!.draw(at: NSPoint(x: titleXPos, y: titleYPos), withAttributes: titleAttributes)
            
            bottomEdge = titleYPos
        }
        
        //Recording Time
        let timeAttributes: [NSAttributedStringKey:AnyObject] = [NSAttributedStringKey.font:NSFont.systemFont(ofSize: 12),
            NSAttributedStringKey.foregroundColor:fontColor]
        
        var time: NSString? = parent.session!.formattedRange as NSString?
        if time == nil { time = "" }
        let timeSize = time!.size(withAttributes: timeAttributes)
        //let timeXPos = bounds.midX - timeSize.width * 0.5
        let timeXPos = leftOffset
        let timeYPos = titleYPos - lineOffset - timeSize.height
        time!.draw(at: NSPoint(x: timeXPos, y: timeYPos), withAttributes: timeAttributes)
        
        bottomEdge = timeYPos
        
        return bounds.height - bottomEdge
    }
    
    @IBAction func setSessionResolution(sender: NSPopUpButton) {
        if parent.session != nil {
            sender.title = sender.titleOfSelectedItem!
            if allResolutions != nil {
                if allResolutions!.count >= sender.indexOfSelectedItem {
                    parent.session!.resolution = allResolutions![sender.indexOfSelectedItem - 1]
                }
                else {
                    let newRes = AddResolutionSheet(windowNibName: NSNib.Name(rawValue: "AddResolutionSheet"))
                    app!.mainWindow!.activeSheet = newRes
                    newRes.graphHeader = self
                    app!.mainWindow!.window!.beginSheet(newRes.window!, completionHandler: nil)
                }
            }
            if let game = app!.mainWindow.table.selectedGame {
                game.saveToFile(directory: app!.dataDirectory)
            }
        }
    }
    
    @IBAction func setGraphicsSettings(sender: NSPopUpButton) {
        if parent.session != nil && !sender.isTransparent {
            if sender.selectedTag() > -1 {
                sender.title = sender.titleOfSelectedItem!
                parent.session!.graphicsSetting = sender.titleOfSelectedItem!
            }
            else {
                let newGLevel = AddGraphicsSheet(windowNibName: NSNib.Name(rawValue: "AddGraphicsSheet"))
                app!.mainWindow!.activeSheet = newGLevel
                newGLevel.graphHeader = self
                app!.mainWindow!.window!.beginSheet(newGLevel.window!, completionHandler: nil)
            }
            if let game = app!.mainWindow.table.selectedGame {
                game.saveToFile(directory: app!.dataDirectory)
            }
        }
    }
    
    func initializeResolutionPopUp(resolutions: [Resolution]) {
        resolution.removeAllItems()
        resolution.addItem(withTitle: "Set...")
        allResolutions = resolutions.sorted(by: {(resA: Resolution,resB: Resolution) -> Bool in
            if resA.width > resB.width { return true }
            else { return false }
        })
        for res in allResolutions! {
            resolution.addItem(withTitle: res.text)
        }
        resolution.menu?.addItem(NSMenuItem.separator())
        resolution.addItem(withTitle: "Other...")
    }
    
    @IBAction func showSystemHardwareDetails(sender: NSControl) {
        if parent.session != nil && parent.session!.systemInformation != nil {
            if let details = popover.contentViewController?.view as? GraphSysInfoDetails {
                details.systemInformation = parent.session!.systemInformation
                details.needsDisplay = true
                popover.animates = true
                popover.show(relativeTo: sender.frame, of: self, preferredEdge: NSRectEdge.maxX)
            }
        }
    }
}








