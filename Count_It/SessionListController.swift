//
//  SessionListController.swift
//  Count_It
//
//  Created by Michael LaRandeau on 8/11/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa
import Carbon

class SessionListController: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    @IBOutlet weak var list: NSTableView!
    let displayDateFormatter = DateFormatter()
    let locale: NSLocale = NSLocale.autoupdatingCurrent as NSLocale
    
    var selectedSession : Session? {
        get {
            let game = app!.mainWindow.table.selectedGame
            let index = list.selectedRow
            if game != nil && index >= 0 {
                return game!.sessions[index]
            }
            return nil
        }
    }
    
    var clickedSession : Session? {
        get {
            let game = app!.mainWindow.table.selectedGame
            let index = list.clickedRow
            if game != nil && index >= 0 {
                return game!.sessions[index]
            }
            return nil
        }
    }
    
    override init() {
        displayDateFormatter.locale = locale as Locale!
        //displayDateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
        displayDateFormatter.dateStyle = DateFormatter.Style.long
        displayDateFormatter.timeStyle = DateFormatter.Style.short
    }
    
    @objc func updateSessionTitle(notification: NSNotification) {
        if let text = notification.object as? NSTextField {
            app!.mainWindow.table.selectedGame!.sessions[list.selectedRow].title = text.stringValue
            if let game = app!.mainWindow.table.selectedGame {
                game.saveToFile(directory: app!.dataDirectory)
            }
            app!.mainWindow.updateGraphSession()
        }
    }
    
    @IBAction func removeSelectedSession(button:AnyObject) {
        if let session = selectedSession {
            removeSession(session: session)
        }
    }
    
    @IBAction func removeClickedSession(button:AnyObject) {
        if let session = clickedSession {
            removeSession(session: session)
        }
    }
    
    func removeSession(session: Session) {
        let title = session.title != nil ? session.title! : "Untitled"
        if let game = app!.mainWindow.table.selectedGame {
            let confirm = NSAlert()
            confirm.messageText = "Are you sure you want to remove \n\"\(title)\"\n from \(game.name)'s recordings?"
            confirm.addButton(withTitle: "Cancel")
            confirm.addButton(withTitle: "Remove")
            if confirm.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn {
                for i in 0..<game.sessions.count {
                    if game.sessions[i] == session {
                        game.sessions[i].deleteFile(directory: app!.recordingDirectory)
                        game.sessions.remove(at: i)
                        list.reloadData()
                        game.saveToFile(directory: app!.dataDirectory)
                        app!.mainWindow.updateGraphSession()
                        break
                    }
                }
            }
        }
        else {
            Supportive.alert(message: "Could not determine the game that \(title) belongs to.")
        }
    }
    
    @IBAction func exportSelectedSessionAsCSV(sender:AnyObject) {
        if let session = selectedSession {
            exportSessionAsCSV(session: session)
        }
    }
    
    @IBAction func exportClickedSessionAsCSV(sender:AnyObject) {
        if let session = clickedSession {
            exportSessionAsCSV(session: session)
        }
    }
    
    @IBAction func exportSessionAsPNG(sender: AnyObject) {
        if let session = selectedSession {
            exportSessionAsImage(session: session, fileType: NSBitmapImageRep.FileType.png)
        }
    }
    
    @IBAction func exportSessionAsJPEG(sender: AnyObject) {
        if let session = selectedSession {
            exportSessionAsImage(session: session, fileType: NSBitmapImageRep.FileType.jpeg)
        }
    }
    
    func exportSessionAsImage(session: Session, fileType: NSBitmapImageRep.FileType) {
        let savePanel = NSSavePanel()
        if fileType == NSBitmapImageRep.FileType.png {
            savePanel.allowedFileTypes = ["png"]
        }
        else if fileType == NSBitmapImageRep.FileType.jpeg {
            savePanel.allowedFileTypes = ["jpeg"]
        }
        savePanel.allowsOtherFileTypes = false
        //savePanel.directoryURL = NSURL(fileURLWithPath: app!.rootSaveDirectory)
        savePanel.nameFieldStringValue = session.title != nil ? session.title! : "Untitled"
        savePanel.beginSheetModal(for: app!.mainWindow!.window!, completionHandler: { [unowned self] (selection:NSApplication.ModalResponse) in
            if selection == NSApplication.ModalResponse.OK && savePanel.url != nil {
                if let graphView = self.app!.mainWindow.graph.view as? GraphView {
                    if let bitmap = GraphImageGenerator().generateImage(header: graphView.header, content: graphView.content, imageType: fileType) {
                        if let imageData = bitmap.representation(using: fileType, properties: [:]) {
                            if !FileManager.default.createFile(atPath: savePanel.url!.path, contents: imageData, attributes: nil) {
                                Supportive.alert(message: "An error occurred while creating the image")
                            }
                        }
                    }
                }
            }
        })
    }
    
    func exportSessionAsCSV(session: Session) {
        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["csv"]
        savePanel.allowsOtherFileTypes = false
        //savePanel.directoryURL = NSURL(fileURLWithPath: app!.rootSaveDirectory)
        savePanel.nameFieldStringValue = session.title != nil ? session.title! : "Untitled"
        savePanel.beginSheetModal(for: app!.mainWindow!.window!, completionHandler: { [unowned self] (selection:NSApplication.ModalResponse) in
            if selection == NSApplication.ModalResponse.OK && savePanel.url != nil {
                if let game = self.app!.mainWindow.table.selectedGame {
                    let report = self.app!.mainWindow!.generateReport(session: session, game: game)
                    if let data = report.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                        if !FileManager.default.createFile(atPath: savePanel.url!.path, contents: data, attributes: nil) {
                            Supportive.alert(message: "An error occured while saving the file.")
                        }
                    }
                }
            }
        })
    }
    
    func updateMenuItems() {
        if let sessionMenu = app!.menu.menu.item(withTitle: "Recording")?.submenu {
            let shouldEnable = selectedSession != nil ? true : false
            sessionMenu.item(withTitle: "Export")?.isEnabled = shouldEnable
            sessionMenu.item(withTitle: "Remove Recording")?.isEnabled = shouldEnable
            sessionMenu.item(withTitle: "Share")?.isEnabled = shouldEnable
        }
    }
    
    @IBAction func openRecordingHelp(sender: AnyObject) {
        if let helpBookName = Bundle.main.object(forInfoDictionaryKey: "CFBundleHelpBookName") as? String {
            //NSHelpManager.sharedHelpManager().openHelpAnchor("anchor", inBook: helpBookName)
            AHGotoPage(helpBookName as CFString!, "pages/recordingIndex.html" as CFString!, nil)
        }
    }
    
    
    //NSTableViewDelegate Protocol
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        for index in proposedSelectionIndexes {
            let cell = list.view(atColumn: 0, row: index, makeIfNecessary: false)
            if cell == nil { return NSIndexSet() as IndexSet }
            else if cell is SessionListCell { continue }
            else { return NSIndexSet() as IndexSet }
        }
        return proposedSelectionIndexes
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let selectedGame = app!.mainWindow.table.selectedGame
        if selectedGame == nil {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SessionNoGame"), owner: self) as? NSTableCellView {
                return cell
            }
        }
        else if selectedGame?.sessions.count == 0 {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SessionNoSessions"), owner: self) as? NSTableCellView {
                return cell;
            }

        }
        else {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SessionCell"), owner: self) as? SessionListCell {
                if let selectedGame = app!.mainWindow.table.selectedGame {
                    if let title = selectedGame.sessions[row].title { cell.recordingTitle.stringValue = title }
                    else { cell.recordingTitle.stringValue = "" }
                    if let start = selectedGame.sessions[row].start {
                        cell.textField!.stringValue = displayDateFormatter.string(from: start as Date)
                    }
                    NotificationCenter.default.addObserver(self, selector: #selector(SessionListController.updateSessionTitle(notification:)), name: NSNotification.Name(rawValue: "NSControlTextDidEndEditingNotification"), object: cell.recordingTitle)
                }
                return cell
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if let selectedGame = app!.mainWindow.table.selectedGame {
            if selectedGame.sessions.count == 0 {
                return 95
            }
        }
        return 40
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateMenuItems()
        app!.mainWindow.updateGraphSession()
    }
    
    
    //NSTableViewDataSource Protocol
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let selectedGame = app!.mainWindow.table.selectedGame {
            if selectedGame.sessions.count == 0 { return 1 }
            else { return selectedGame.sessions.count }
        }
        else { return 1 }
    }
    
    //NSMenuDelegate
    func menuWillOpen(_ menu: NSMenu) {
        let selectedGame = app!.mainWindow.table.selectedGame
        var enabled = true;
        if selectedGame == nil || selectedGame?.sessions.count == 0 { enabled = false }
        
        for item in menu.items {
            item.isEnabled = enabled
        }
    }

}
