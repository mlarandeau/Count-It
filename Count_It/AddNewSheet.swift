//
//  AddNewSheet.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/17/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class AddNewSheet: NSWindowController, NSWindowDelegate {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    @IBOutlet var table: AddNewListController!
    @IBOutlet var message: NSTextField!
    @IBOutlet var progress: NSProgressIndicator!
    
    var opQueue: OperationQueue = OperationQueue()
    var operation: BlockOperation = BlockOperation()
    var hasStartedSearch = false
    
    @IBAction func addApp(sender:NSButton) {
        let selectedGames = table.selectedGames
        if selectedGames != nil {
            for game in selectedGames! {
                app!.checkToAddGameToCollection(game: game)
            }
        }
        app!.mainWindow.activeSheetType = "Complete"
        closeSheet(response: NSApplication.ModalResponse.OK)
    }
    
    @IBAction func cancel(sender:NSButton) {
        closeSheet(response: NSApplication.ModalResponse.cancel)
    }
    
    func closeSheet(response: NSApplication.ModalResponse) {
        operation.cancel()
        opQueue.cancelAllOperations()
        NSWorkspace.shared.removeObserver(table, forKeyPath: "runningApplications")
        if window!.sheetParent != nil {
            window!.sheetParent!.endSheet(window!, returnCode: response)
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AddNewSheet.windowDidBecomeKey(_:)), name: NSWindow.didBecomeKeyNotification, object: window!)
        
        progress.startAnimation(self)
        
        message.stringValue = (("Retrieving " + app!.mainWindow.activeSheetType! as NSString).lastPathComponent as NSString).deletingPathExtension + " games..."
    }
    
    func windowDidBecomeKey(_ notification:Notification) {
        if !hasStartedSearch {
            hasStartedSearch = true
            operation.addExecutionBlock({ [unowned self] () in
                self.table.updateAppCollection()
                })
            operation.completionBlock = { [unowned self] () in
                if !self.operation.isCancelled {
                    DispatchQueue.main.async(execute: {
                        if !self.operation.isCancelled {
                            self.table.view.reloadData()
                            self.progress.stopAnimation(self)
                            if self.app!.mainWindow.activeSheetType! == "Running" {
                                self.message.stringValue = "Currently running applications:"
                            }
                            else {
                                self.message.stringValue = "Testing"
                                self.message.stringValue = ((self.app!.mainWindow.activeSheetType! as NSString).lastPathComponent as NSString).deletingPathExtension + " library:"
                            }
                        }
                    })
                }
                NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: self.window!)
            }
            opQueue.addOperation(operation)
        }
    }
}
