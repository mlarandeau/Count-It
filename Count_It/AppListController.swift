//
//  AppListController.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/2/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa
import Carbon

class AppListController: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    @IBOutlet weak var view : AppListView!
    
    var selectedCell : AppListCell? {
        get {
            if view.selectedRow >= 0 {
                return view.view(atColumn: 0, row: view.selectedRow, makeIfNecessary: true) as? AppListCell
            }
            return nil
        }
    }
    
    var selectedGame : Game? {
        get {
            let index = view.selectedRow
            if index >= 0 && index < app!.games.count {
                return app!.games[index]
            }
            else { return nil }
        }
    }
    
    var clickedCell : AppListCell? {
        get {
            if view.clickedRow >= 0 {
                return view.view(atColumn: 0, row: view.clickedRow, makeIfNecessary: true) as? AppListCell
            }
            return nil
        }
    }
    
    var clickedGame : Game? {
        get {
            let index = view.clickedRow
            if index >= 0 {
                return app!.games[index]
            }
            else { return nil }
        }
    }
    
    @objc func updateGameTitle(notification: NSNotification) {
        if let text = notification.object as? NSTextField {
            if let game = app!.mainWindow.table.selectedGame {
                game.displayName = text.stringValue
                game.saveToFile(directory: app!.dataDirectory)
                app!.mainWindow.updateGraphSession()
            }
        }
    }
    
    @IBAction func openAddGameHelp(sender: AnyObject) {
        if let helpBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            AHGotoPage(helpBookName as CFString!, "pages/addingGame.html" as CFString!, nil)
        }
    }
    
    //NSTableViewDelegate Methods
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        for index in proposedSelectionIndexes {
            let cell = tableView.view(atColumn: 0, row: index, makeIfNecessary: false)
            if cell == nil { return NSIndexSet() as IndexSet }
            else if cell is AppListCell { continue }
            else { return NSIndexSet() as IndexSet }
        }
        return proposedSelectionIndexes
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if app!.games.count == 0 { return 62 }
        else { return 50 }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if app!.games.count == 0 {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AppListNoGame"), owner: self) as? NSTableCellView {
                return cell;
            }
        }
        else {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AppName"), owner: self) as? AppListCell {
                cell.imageView?.image = app!.games[row].icon
                if let displayName = app!.games[row].displayName {
                    cell.textField!.stringValue = displayName
                }
                else {
                    cell.textField!.stringValue = app!.games[row].name
                }
                if app!.tracer.activeGame == app!.games[row] {
                    cell.statusView.image = NSImage(named: NSImage.Name(rawValue: "NSStatusAvailable"))
                }
                else if app!.tracer.waitingFor == app!.games[row] {
                    cell.statusView.image = NSImage(named: NSImage.Name(rawValue: "NSStatusPartiallyAvailable"))
                }
                else {
                    cell.statusView.image = nil
                }
                NotificationCenter.default.addObserver(self, selector: #selector(AppListController.updateGameTitle(notification:)), name: NSNotification.Name(rawValue: "NSControlTextDidEndEditingNotification"), object: cell.textField)
                
                return cell
            }
        }

        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        /*if app!.tracer.activeGame == nil && app!.tracer.waitingFor == nil {
            if selectedGame != nil {
                if app!.tracer.activeGame == nil { app!.mainWindow.window!.title = selectedGame!.name }
            }
            else {
                app!.mainWindow.window!.title = "Collection"
            }
        }*/
        app!.mainWindow.toolbar.updateIcons(game: selectedGame)
        app!.mainWindow.sessionList.list.reloadData()
        app!.mainWindow.updateGraphSession()
    }
    
    //NSTableViewDataSource Methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        if app!.games.count == 0 { return 1 }
        else { return app!.games.count }
    }
    
    //Methods
    func selectGame(game: Game) {
        for i in 0 ..< app!.games.count {
            if app!.games[i].name == game.name {
                view.selectRowIndexes(NSIndexSet(index: i) as IndexSet, byExtendingSelection: false)
                return
            }
        }
        app!.mainWindow!.sessionList.list.deselectAll(nil)
    }
    
    @IBAction func browseForApp(option:NSMenuItem) {
        let open = NSOpenPanel()
        open.allowedFileTypes = ["app"]
        open.allowsMultipleSelection = true
        var lastLocation: String? = UserDefaults.standard.string(forKey: "NSNavLastRootDirectory")
        if lastLocation == nil { lastLocation = "/Applications" }
        open.directoryURL = NSURL(fileURLWithPath: lastLocation!) as URL
        open.prompt = "Add"
        open.beginSheetModal(for: view.window!, completionHandler: { [unowned self] (selection:NSApplication.ModalResponse) in
            if selection == NSApplication.ModalResponse.OK {
                for url in open.urls {
                    if let newGame = Game(url: url as NSURL) {
                        self.app!.checkToAddGameToCollection(game: newGame)
                        _ = self.reload()
                        self.app!.tracer.checkAndAttachToGame()
                    }
                }
            }
        })
    }
    
    @IBAction func addRunningApp(option:NSMenuItem) {
        app!.mainWindow.runAddNewAsModal(type: "Running")
    }
    
    @IBAction func addServiceApp(option:NSMenuItem) {
        app!.mainWindow.runAddNewAsModal(type: "Service")
    }
    
    @IBAction func removeSelectedApp(button:AnyObject) {
        if selectedGame != nil {
            removeGame(game: selectedGame!)
        }
    }
    
    @IBAction func removeClickedApp(button:AnyObject) {
        if clickedGame != nil {
            removeGame(game: clickedGame!)
        }
    }
    
    func removeGame(game: Game) {
        if app!.tracer.activeGame != nil && app!.tracer.activeGame!.name == game.name {
            let alert = NSAlert()
            alert.messageText = "\(game.name) is currently being tracked.\nStop tracking the frame rate and try again."
            alert.runModal()
        }
        else {
            let confirm = NSAlert()
            confirm.messageText = "Are you sure you want to remove \n\(game.name)\n from your collection?\n(This will remove all recordings for this game as well.)"
            confirm.addButton(withTitle: "Cancel")
            confirm.addButton(withTitle: "Remove")
            if confirm.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn {
                game.deleteFiles(gameDirectory: app!.dataDirectory, sessionDirectory: app!.recordingDirectory)
                app!.games.remove(name: game.name)
                if !reload() {
                    app!.mainWindow.sessionList.list.reloadData()
                    app!.mainWindow.updateGraphSession()
                }
                app!.mainWindow.toolbar.updateIcons(game: nil)
            }
        }
    }
    
    func reload()->Bool {
        let previousGame = self.selectedGame
        view.reloadData()
        if previousGame != nil {
            selectGame(game: previousGame!)
            return true
        }
        return false
    }
    
    func setGameStatus(game:Game,status:String) {
        DispatchQueue.main.async(execute: { [unowned self] () in
            var gameCell: AppListCell? = nil
            var i = 0;
            var row = self.view.view(atColumn: 0, row: i, makeIfNecessary: true) as? AppListCell
            while (row != nil) {
                if row!.textField!.stringValue == game.name || row!.textField!.stringValue == game.displayName {
                    gameCell = row
                    break
                }
                i += 1
                row = self.view.view(atColumn: 0, row: i, makeIfNecessary: true) as? AppListCell
            }
            if gameCell != nil {
                if status == "Stop" {
                    gameCell!.statusView.image = nil
                }
                else if status == "Wait" {
                    gameCell!.statusView.image = NSImage(named: NSImage.Name(rawValue: "NSStatusPartiallyAvailable"))
                }
                else if status == "Attached" {
                    gameCell!.statusView.image = NSImage(named: NSImage.Name(rawValue: "NSStatusAvailable"))
                }
            }
        })
    }
    
    /*** NSMenuDeleagte ***/
    func menuWillOpen(_ menu: NSMenu) {
        var enabled = true
        if app!.games.count == 0 { enabled = false }
        
        for item in menu.items {
            item.isEnabled = enabled
        }
    }
}









