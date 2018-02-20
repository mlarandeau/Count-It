//
//  AppListView.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/11/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class AppListView: NSTableView {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    
    //NSDraggingDestination Protocol
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if canAcceptDrag(info: sender,add: false) { return NSDragOperation.link }
        else { return [] }
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if canAcceptDrag(info: sender,add: false) { return NSDragOperation.link }
        else { return [] }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if canAcceptDrag(info: sender,add: true) { return true }
        else { return false }
    }
    
    func canAcceptDrag(info: NSDraggingInfo,add:Bool)->Bool {
        var toAdd: [NSURL] = []
        let pBoard = info.draggingPasteboard()
        if pBoard.types != nil {
            let types = pBoard.types! as NSArray
            if types.contains(NSPasteboard.PasteboardType(kUTTypeURL as String)) {
                let potentialGames = pBoard.readObjects(forClasses: [NSURL.self], options: [:]) as? [NSURL]
                if potentialGames != nil {
                    for url in potentialGames! {
                        if url.path != nil {
                            let gameURL = NSURL(fileURLWithPath: url.path!, isDirectory: false)
                            if gameURL.pathExtension != nil {
                                var isAllowed = false
                                if gameURL.pathExtension! == "app" {
                                    isAllowed = true
                                }
                                else {
                                    var typeIdentifier: AnyObject? = nil
                                    do {
                                        try url.getResourceValue(&typeIdentifier, forKey: URLResourceKey.typeIdentifierKey)
                                        
                                        if let utiString = typeIdentifier as? String {
                                            if utiString == "public.unix-executable" {
                                                isAllowed = true
                                            }
                                        }
                                    }
                                    catch {
                                        isAllowed = false
                                    }
                                }
                                if isAllowed {
                                    toAdd += [gameURL]
                                }
                            }
                            /*if gameURL.pathExtension != nil && gameURL.pathExtension! == "app" {
                                toAdd += [gameURL]
                            }*/
                        }
                    }
                }
            }
        }
        if toAdd.count > 0 {
            if add {
                for url in toAdd {
                    if let newGame = Game(url: url) {
                        app!.checkToAddGameToCollection(game: newGame)
                    }
                }
                _ = app!.mainWindow.table.reload()
                app!.tracer.checkAndAttachToGame()
            }
            return true
        }
        else { return false }
    }

    //Methods
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
}
