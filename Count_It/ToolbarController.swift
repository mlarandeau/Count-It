//
//  ToolbarController.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/5/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class ToolbarController: NSObject, NSToolbarDelegate, NSSharingServicePickerDelegate, NSSharingServiceDelegate {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    @IBOutlet weak var toolbar: NSToolbar!
    @IBOutlet var action : NSToolbarItem!
    @IBOutlet var wait : NSToolbarItem!
    @IBOutlet var stop : NSToolbarItem!
    @IBOutlet var zoom : NSPopUpButton!
    @IBOutlet var zoomSlider : NSSlider!
    var zoomLevel: Int = 100
    @IBOutlet var toggleSessionView : NSButton!
    @IBOutlet var shareButton: NSButton!
    var showSessionOptions = false
    
    @IBAction func toggleSessionView(button: AnyObject) {
        if toggleSessionView.state == .on {
            showSessionOptions = true
        }
        else {
            showSessionOptions = false
        }
        
        if !showSessionOptions { toggleSessionIcons() }
        app!.mainWindow.toggleSessions(shouldShowSessions: showSessionOptions, completion: {
            if self.showSessionOptions { self.toggleSessionIcons() }
        })
        
        UserDefaults.standard.set(toggleSessionView.state, forKey: "MLShouldDisplayGraph")
    }
    
    func toggleSessionIcons() {
        if showSessionOptions {
            if (toolbar.items[4]).itemIdentifier.rawValue != "Zoom" {
                toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier(rawValue: "Zoom"), at: 4)
            }
            if (toolbar.items[5]).itemIdentifier.rawValue != "Share" {
                toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier(rawValue: "Share"), at: 5)
            }
            toggleSessionView.image = NSImage(named: NSImage.Name(rawValue: "GraphSelected"))
            if let viewMenu = app!.menu.menu.item(withTitle: "View") {
                if let toggleGraph = viewMenu.submenu?.item(withTitle: "Show Graph") {
                    toggleGraph.title = "Hide Graph"
                    if let zoomItem = viewMenu.submenu?.item(withTitle: "Zoom") {
                        zoomItem.isEnabled = true
                    }
                }
            }
        }
        else {
            if (toolbar.items[4]).itemIdentifier.rawValue == "Zoom" {
                toolbar.removeItem(at: 4)
            }
            if (toolbar.items[4]).itemIdentifier.rawValue == "Share" {
                toolbar.removeItem(at: 4)
            }
            toggleSessionView.image = NSImage(named: NSImage.Name(rawValue: "Graph"))
            if let viewMenu = app!.menu.menu.item(withTitle: "View") {
                if let toggleGraph = viewMenu.submenu?.item(withTitle: "Hide Graph") {
                    toggleGraph.title = "Show Graph"
                    if let zoomItem = viewMenu.submenu?.item(withTitle: "Zoom") {
                        zoomItem.isEnabled = false
                    }
                }
            }
        }
    }
    
    @IBAction func zoom(button:AnyObject) {
        if let popUp = button as? NSPopUpButton {
            popUp.title = popUp.titleOfSelectedItem!
            for item in popUp.itemArray {
                if item == popUp.selectedItem { item.state = .on }
                else { item.state = .off }
            }
        }
        else if let menuItem = button as? NSMenuItem {
            zoom.title = menuItem.title
            for item in zoom.itemArray {
                if item.tag == menuItem.tag {
                    item.state = .on
                    zoom.select(item)
                }
                else { item.state = .off }
            }
        }
        else if let slider = button as? NSSlider {
            zoomLevel = Int(slider.doubleValue)
            let numFormatter = NumberFormatter()
            numFormatter.numberStyle = NumberFormatter.Style.none
            numFormatter.minimumFractionDigits = 0
            numFormatter.maximumFractionDigits = 0
            zoom.title = (numFormatter.string(from: NSNumber(value: Double(zoomLevel)))! as String) + "%"
            if let selected = zoom.selectedItem {
                selected.state = .off
            }
            zoom.select(nil)
        }
        app!.mainWindow.updateGraphSession()
    }
    
    @IBAction func showSharePicker(sender:NSButton) {
        let aMenu = NSMenu(title: "Sharing")
        let allServices = NSSharingService.sharingServices(forItems: [NSImage()])
        for service in allServices {
            let newItem = NSMenuItem(title: service.title, action: #selector(MainMenuController.share(sender:)), keyEquivalent: "")
            newItem.image = service.image
            newItem.representedObject = service
            newItem.target = app?.menu
            aMenu.addItem(newItem)
        }
        aMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.frame.size.height), in: sender)
    }
    
    @IBAction func start(button:AnyObject) {
        if app!.tracer.activeGame == nil {
            if let game = app!.mainWindow.table.selectedGame {
                launchOrAttachToGame(game: game)
            }
        }
    }
    
    @IBAction func stop(button:AnyObject) {
        detachFromGame()
        app!.tracer.waitingFor = nil
    }
    
    @IBAction func wait(button:AnyObject) {
        if app!.tracer.activeGame == nil {
            if let game = app!.mainWindow.table.selectedGame {
                waitForGameToLaunch(game: game)
            }
        }
    }
    
    func launchOrAttachToGame(game:Game) {
        app!.mainWindow.progress.startAnimation(self)
        app!.mainWindow.table.setGameStatus(game: game, status: "Wait")
        if game.isRunning {
            app!.tracer.attachToGame(game: game)
            updateIcons(game: game)
        }
        else if let gameURL = game.url {
            waitForGameToLaunch(game: game)
            let launchedApp = try? NSWorkspace.shared.launchApplication(at: gameURL as URL, options: NSWorkspace.LaunchOptions.default, configuration: [:])
            if launchedApp == nil {
                app!.mainWindow.progress.stopAnimation(self)
                app!.mainWindow.table.setGameStatus(game: game, status: "Stop")
                Supportive.alert(message: "There was an error launching \(game.name)")
            }
        }
    }
    
    func detachFromGame() {
        var game: Game? = nil
        if let activeGame = app?.tracer.activeGame { game = activeGame }
        else if let activeGame = app?.tracer.waitingFor { game = activeGame }
        if game != nil { app!.mainWindow.table.setGameStatus(game: game!, status: "Stop") }
        if app!.tracer.activeSession != nil { app!.tracer.endSession() }
        app!.mainWindow.detachFromApp()
    }
    
    func waitForGameToLaunch(game:Game) {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Connect to trace helper.")
        app!.mainWindow.progress.startAnimation(self)
        app!.tracer.waitingFor = game
        app!.mainWindow.table.setGameStatus(game: game, status: "Wait")
        updateIcons(game: game)
    }
    
    func updateIcons(game: Game?) {
        //let collectionMenu = app!.menu.menu.itemWithTitle("Collection")!
        let gameMenu = app!.menu.menu.item(withTitle: "Game")!
        if game != nil {
            gameMenu.submenu!.item(withTitle: "Remove Game")!.isEnabled = true
            gameMenu.isEnabled = true
            /*if app!.tracer.waitingFor != nil {
                action.image = NSImage(named: "Launch")
                action.toolTip = "Launch and track the framerate"
                action.label = "Launch"
                action.enabled = false
                stop.enabled = true
                wait.enabled = false
            }*/
            if app!.tracer.activeGame != nil || app!.tracer.waitingFor != nil {
                action.image = NSImage(named: NSImage.Name(rawValue: "Start"))
                action.toolTip = "Track the framerate"
                action.label = "Start"
                action.isEnabled = false
                stop.isEnabled = true
                wait.isEnabled = false
                
                gameMenu.submenu!.item(withTitle: "Launch")!.isEnabled = false
                gameMenu.submenu!.item(withTitle: "Start")!.isEnabled = false
                gameMenu.submenu!.item(withTitle: "Stop")!.isEnabled = true
                gameMenu.submenu!.item(withTitle: "Wait")!.isEnabled = false
            }
            else if game!.isRunning {
                action.image = NSImage(named: NSImage.Name(rawValue: "Start"))
                action.toolTip = "Track the framerate"
                action.label = "Start"
                action.isEnabled = true
                stop.isEnabled = false
                wait.isEnabled = false
                
                gameMenu.submenu!.item(withTitle: "Launch")!.isEnabled = false
                gameMenu.submenu!.item(withTitle: "Start")!.isEnabled = true
                gameMenu.submenu!.item(withTitle: "Stop")!.isEnabled = false
                gameMenu.submenu!.item(withTitle: "Wait")!.isEnabled = false
            }
            else {
                action.image = NSImage(named: NSImage.Name(rawValue: "Launch"))
                action.toolTip = "Launch and track the framerate"
                action.label = "Launch"
                action.isEnabled = true
                stop.isEnabled = false
                wait.isEnabled = true
                
                gameMenu.submenu!.item(withTitle: "Launch")!.isEnabled = true
                gameMenu.submenu!.item(withTitle: "Start")!.isEnabled = false
                gameMenu.submenu!.item(withTitle: "Stop")!.isEnabled = false
                gameMenu.submenu!.item(withTitle: "Wait")!.isEnabled = true
            }
        }
        else {
            action.image = NSImage(named: NSImage.Name(rawValue: "Launch"))
            action.toolTip = "Launch and track the framerate"
            action.label = "Launch"
            action.isEnabled = false
            stop.isEnabled = false
            wait.isEnabled = false
            
            gameMenu.submenu!.item(withTitle: "Remove Game")!.isEnabled = false
            gameMenu.submenu!.item(withTitle: "Launch")!.isEnabled = false
            gameMenu.submenu!.item(withTitle: "Start")!.isEnabled = false
            gameMenu.submenu!.item(withTitle: "Stop")!.isEnabled = false
            gameMenu.submenu!.item(withTitle: "Wait")!.isEnabled = false
        }
    }
}
