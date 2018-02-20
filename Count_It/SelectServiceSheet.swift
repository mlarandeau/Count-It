//
//  SelectServiceSheet.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/19/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class SelectServiceSheet: NSWindowController, NSWindowDelegate {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    var query: NSMetadataQuery?
    @IBOutlet var matrix: NSMatrix!
    @IBOutlet var next: NSButton!
    @IBOutlet var progress: NSProgressIndicator!
    @IBOutlet var message: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()
        
        matrix.prototype = matrix.cell(atRow: 0, column: 0)!.copy() as? NSCell
        
        progress.startAnimation(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SelectServiceSheet.searchForServices(notification:)), name: NSWindow.didBecomeKeyNotification, object: window!)
        
        listAllAppsInDirectory(filePath: app!.logFilePath, dir: "/Applications")
        listAllAppsInDirectory(filePath: app!.logFilePath, dir: "/Aplicaciones")
        Supportive.appendToFile(path: app!.logFilePath, data: "\n\(NSDate(timeIntervalSinceNow: 0).description): Service window loaded")
    }
    
    @IBAction func enableNext(sender:NSControl) {
        next.isEnabled = true
    }
    
    @objc func searchForServices(notification:NSNotification) {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Started Search")
        query = NSMetadataQuery()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SelectServiceSheet.queryFinished(notification:)), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
        let bundleIDs = ["com.valvesoftware.steam","com.macgamestore.Client2","com.gog.galaxy","net.battle.app"]
        var search = ""
        let searchAttribute = "kMDItemCFBundleIdentifier"
        for id in bundleIDs {
            if !search.isEmpty { search += " || " }
            search += "\(searchAttribute) == '\(id)'"
        }
        query!.predicate = NSPredicate(fromMetadataQueryString: search)
        query!.sortDescriptors = [NSSortDescriptor(key: String(kMDItemCFBundleIdentifier), ascending: true)]
        query!.searchScopes = [NSMetadataQueryLocalComputerScope]
        query!.start()
        
        NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: window!)
        
        Supportive.appendToFile(path: app!.logFilePath, data: "Query: \(search)")
    }
    
    @objc func queryFinished(notification:NSNotification) {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Search Complete")
        var foundServices: [String] = []
        
        _ = notification.object! as! NSMetadataQuery
        query!.stop()
        
        for i in 0 ..< query!.resultCount {
            let item = query!.result(at: i) as! NSMetadataItem
            let path = item.value(forAttribute: String(kMDItemPath)) as? String
            if path != nil { foundServices += [path!] }
        }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
        query = nil
        
        if foundServices.count > 0 {
            createButtonMatrix(foundServices: foundServices)
            message.stringValue = "Select a platform:"
            for service in foundServices {
                Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Found \(service)")
            }
        }
        else {
            Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): No supported platforms found.")
            message.stringValue = "No supported platforms found."
        }
        progress.stopAnimation(self)
    }
    
    func createButtonMatrix(foundServices:[String]) {
        for i in 0 ..< foundServices.count {
            var cell = matrix.cell(atRow: 0, column: i) as? NSButtonCell
            if cell == nil {
                matrix.addColumn(with: [matrix.prototype!.copy() as! NSButtonCell])
                cell = matrix.cell(atRow: 0, column: i) as? NSButtonCell
            }
            cell!.title = foundServices[i]
            cell!.image = NSWorkspace.shared.icon(forFile: foundServices[i])
            cell!.imagePosition = NSControl.ImagePosition.imageOnly
        }
        matrix.sizeToCells()
        matrix.setFrameOrigin(NSPoint(x: (matrix.superview!.frame.size.width * 0.5) - matrix.frame.size.width * 0.5, y: matrix.frame.origin.y))
        matrix.deselectAllCells()
    }
    
    @IBAction func chooseService(sender: NSButton) {
        if let cell = matrix.selectedCell() as? NSButtonCell {
            app!.mainWindow.activeSheetType = cell.title
            closeSheet(response: NSApplication.ModalResponse.OK)
        }
        else { closeSheet(response: NSApplication.ModalResponse.cancel) }
    }
    
    @IBAction func cancel(sender: NSButton) {
        closeSheet(response: NSApplication.ModalResponse.cancel)
    }
    
    func closeSheet(response: NSApplication.ModalResponse) {
        if window!.sheetParent != nil {
            window!.sheetParent!.endSheet(window!, returnCode: response)
        }
    }
    
    func listAllAppsInDirectory(filePath:String, dir:String) {
        if let contents = (try? FileManager.default.contentsOfDirectory(atPath: dir)) {
            Supportive.appendToFile(path: app!.logFilePath, data: "\n\(NSDate(timeIntervalSinceNow: 0).description): Apps in \(dir)")
            for file in contents {
                var message = file
                if let bundleID = Bundle(path: "\(dir)/\(file)")?.bundleIdentifier { message += "          " + bundleID }
                Supportive.appendToFile(path: app!.logFilePath, data: message)
            }
        }
    }
}








