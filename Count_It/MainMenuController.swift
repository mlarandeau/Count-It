//
//  MainMenu.swift
//  Count_It
//
//  Created by Michael LaRandeau on 6/27/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class MainMenuController: NSObject, NSMenuDelegate {
    @IBOutlet weak var app: AppDelegate!
    @IBOutlet var menu: NSMenu!
    
    @IBAction func toggleCollectionWindow(sender: NSMenuItem) {
        if sender.state == .on {
            sender.state = .off
            app.mainWindow.close()
        }
        else {
            sender.state = .on
            app.mainWindow.showWindow(nil)
        }
    }
    
    @IBAction func addGame(sender: NSMenuItem) {
        if sender.title == "Browse..." {
            app.mainWindow.table.browseForApp(option: sender)
        }
        else if sender.title == "Platform..." {
            app.mainWindow.table.addServiceApp(option: sender)
        }
        else if sender.title == "Running..." {
            app.mainWindow.table.addRunningApp(option: sender)
        }
    }
    
    @IBAction func removeGame(sender: NSMenuItem) {
        app.mainWindow.table.removeSelectedApp(button: sender)
    }
    
    @IBAction func startOrLaunchGame(sender: NSMenuItem) {
        app.mainWindow.toolbar.start(button: sender)
    }
    
    @IBAction func stopGame(sender: NSMenuItem) {
        app.mainWindow.toolbar.stop(button: sender)
    }
    
    @IBAction func waitForGame(sender: NSMenuItem) {
        app.mainWindow.toolbar.wait(button: sender)
    }
    
    @IBAction func attachToProcess(sender: NSMenuItem) {
        app.mainWindow.showAttachToProcessSheet()
    }
    
    @IBAction func removeSession(sender: NSMenuItem) {
        app.mainWindow.sessionList.removeSelectedSession(button: sender)
    }
    
    @IBAction func exportSessionAsCSV(sender: NSMenuItem) {
        app.mainWindow.sessionList.exportSelectedSessionAsCSV(sender: sender)
    }
    
    @IBAction func exportSessionAsPNG(sender: NSMenuItem) {
        app.mainWindow.sessionList.exportSessionAsPNG(sender: sender)
    }
    
    @IBAction func exportSessionAsJPEG(sender: NSMenuItem) {
        app.mainWindow.sessionList.exportSessionAsJPEG(sender: sender)
    }
    
    @IBAction func toggleGraphView(sender: NSMenuItem) {
        if sender.title == "Show Graph" {
            app!.mainWindow.toolbar.toggleSessionView.state = .on
        }
        else if sender.title == "Hide Graph" {
            app!.mainWindow.toolbar.toggleSessionView.state = .off
        }
        app.mainWindow.toolbar.toggleSessionView(button: sender)
    }
    
    @IBAction func zoom(sender: NSMenuItem) {
        app!.mainWindow.toolbar.zoom(button: sender)
    }
    
    func finalizeShareItems(service: NSSharingService, shareItems: [AnyObject])->[AnyObject] {
        var shareItemsFinal: [AnyObject] = []
        let twitterService = NSSharingService(named: NSSharingService.Name.postOnTwitter)
        let mailService = NSSharingService(named: NSSharingService.Name.composeEmail)
        let airDropService = NSSharingService(named: NSSharingService.Name.sendViaAirDrop)
        if twitterService != nil && service == twitterService {
            for item in shareItems {
                if let message = item as? String {
                    shareItemsFinal.append((message + " #CountIt @MacGamerHQ") as AnyObject)
                }
                else {
                    shareItemsFinal.append(item)
                }
                
            }
        }
        else if mailService != nil && service == mailService {
            service.subject = "Count It Frame Rate Data"
            service.recipients = ["ric@macgamerhq.com"]
            shareItemsFinal = shareItems
            if let game = app!.mainWindow.table.selectedGame {
                if let session = app!.mainWindow.sessionList.selectedSession {
                    var shouldContinue = true
                    let suppressAlert = UserDefaults.standard.bool(forKey: "MLSuppressMissingDataAlert")
                    if !suppressAlert && (session.resolution == nil || session.graphicsSetting == nil) {
                        let missingDataAlert = NSAlert()
                        var message = "If you are submitting this data to MacGamerHQ, please set the "
                        if session.resolution == nil && session.graphicsSetting == nil {
                            message += "Resolution and Graphics Preset"
                        }
                        else if session.resolution == nil {
                            message += "Resolution"
                        }
                        else if session.graphicsSetting == nil {
                            message += "Graphics Preset"
                        }
                        message += " before continuing."
                        missingDataAlert.messageText = message
                        missingDataAlert.addButton(withTitle: "Cancel")
                        missingDataAlert.addButton(withTitle: "Continue to Mail")
                        missingDataAlert.showsSuppressionButton = true
                        if missingDataAlert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
                            shouldContinue = false
                        }
                        if missingDataAlert.suppressionButton!.state == .on {
                            UserDefaults.standard.set(true, forKey: "MLSuppressMissingDataAlert")
                        }
                    }
                    if shouldContinue {
                        let report = app!.mainWindow!.generateReport(session: session, game: game)
                        if let data = report.data(using: String.Encoding.utf8, allowLossyConversion: false) {
                            let filePath = app!.sharedFilePath!
                            if FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil) {
                                shareItemsFinal.append(NSURL(fileURLWithPath: filePath))
                            }
                            else {
                                Supportive.alert(message: "An error occured while creating the csv")
                            }
                        }
                    }
                    else {
                        shareItemsFinal.removeAll()
                    }
                }
            }
        }
        else if airDropService != nil && service == airDropService {
            for item in shareItems {
                if (item as? String) == nil {
                    shareItemsFinal.append(item)
                }
            }
        }
        else { shareItemsFinal = shareItems }
        
        return shareItemsFinal
    }
    
    @IBAction func share(sender: NSMenuItem) {
        var didCreateImage = false
        if let service = sender.representedObject as? NSSharingService {
            if let graphView = app!.mainWindow.graph.view as? GraphView {
                if let game = app?.mainWindow.table.selectedGame {
                    let shareItems = GraphImageGenerator().generateShareItems(game: game, graph: graphView)
                    if shareItems.count > 0 {
                        let shareItemsFinal = finalizeShareItems(service: service, shareItems: shareItems)
                        if shareItemsFinal.count > 0 {
                            service.perform(withItems: shareItemsFinal)
                        }
                        didCreateImage = true
                    }
                }
            }
        }
        if !didCreateImage { Supportive.alert(message: "There was an error generating the image.") }
    }
}
