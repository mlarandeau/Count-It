//
//  MainWindow.swift
//  Count_It
//
//  Created by Michael LaRandeau on 4/12/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class MainWindow: NSWindowController,NSWindowDelegate,NSDraggingDestination {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    
    @IBOutlet var progress : NSProgressIndicator!
    @IBOutlet var table : AppListController!
    @IBOutlet var toolbar : ToolbarController!
    @IBOutlet var sessionList : SessionListController!
    @IBOutlet var appListFooter : NSView!
    @IBOutlet var graph: GraphController!
    @IBOutlet var splitView: SplitView!
    var activeSheet : NSWindowController?
    var activeSheetType : String?
    var activeSheetResponse: NSApplication.ModalResponse?
    var completedInitialSizing = false
    var completedInitialFading = false
    var isFullscreen = false
    var isRestarting = false

    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.titleVisibility = NSWindow.TitleVisibility.hidden
        window?.backgroundColor = NSColor.white
        
        sessionList.list.intercellSpacing = NSSize(width: sessionList.list.intercellSpacing.width, height: 0)
        
        //Set Background Color of footer to match the game table
        appListFooter.wantsLayer = true
        appListFooter.layer?.backgroundColor = table.view.backgroundColor.cgColor
        
        NSWorkspace.shared.addObserver(self, forKeyPath: "runningApplications", options: [], context: nil)
        
        table.view.registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeURL as String)])
        
        for i in 1..<splitView.subviews.count {
            (splitView.subviews[i] ).isHidden = true
        }
        toolbar.toggleSessionView.state = NSControl.StateValue(rawValue: UserDefaults.standard.integer(forKey: "MLShouldDisplayGraph"))
        toolbar.toggleSessionView(button: toolbar.toggleSessionView)
        toolbar.shareButton.sendAction(on: NSEvent.EventTypeMask(rawValue: UInt64(Int(NSEvent.EventTypeMask.leftMouseDown.rawValue))))
        
        graph.assignNotifications()
        
        //table.addAppButton.setFrameSize(NSSize(width: 50, height: 20))
    }
    
    func windowDidResize(_ notification: Notification) {
        UserDefaults.standard.set(Double(window!.frame.width), forKey: "MLMainWindowWidth")
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        isFullscreen = true
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        isFullscreen = false
    }
    
    func windowWillClose(_ notification: Notification) {
        if let menuItem = app?.menu.menu.item(withTitle: "Window")?.submenu?.item(withTitle: "Collection") {
            menuItem.state = .off
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?){
        if keyPath == "runningApplications" {
            if app!.tracer.activeGame != nil && !app!.tracer.activeGame!.isRunning { detachFromApp() }
            toolbar.updateIcons(game: table.selectedGame)
        }
    }
    
    func generateReport(session: Session, game: Game)->String {
        let preLoaded = session.samples.count > 0 ? true : false
        if !preLoaded { _ = session.loadSamples(directory: app!.recordingDirectory) }
        
        let locale = NSLocale.autoupdatingCurrent
        let sep = locale.decimalSeparator == "," ? ";" : ","
        let numFormatter = NumberFormatter()
        let precision = 2
        numFormatter.minimumFractionDigits = precision
        numFormatter.maximumFractionDigits = precision

        var report = ""
        
        if let sysInfo = session.systemInformation {
            let summaryHeaders: [String] = [ "\"Game Title\"", "\"Mac\"", "\"Model\"", "\"Model Year\"", "\"Processor\"", "\"RAM\"", "\"Graphics\"", "\"Resolution\"", "\"Settings\"", "\"Frame Rate (average)\"" ]
            let computerNameToUse = sysInfo.computerType != "" ? sysInfo.computerType : sysInfo.computerName
            var graphicsInfo = sysInfo.gpuName
            if sysInfo.gpuVRAMGB != "" { graphicsInfo += " (\(sysInfo.gpuVRAMGB))" }
            let summaryData: [String] = [ "\"\(game.displayName ?? game.name)\"",
                                            "\"\(computerNameToUse)\"",
                                            "\"\(sysInfo.computerModel)\"",
                                            "\"\(sysInfo.computerYear)\"",
                                            "\"\(sysInfo.processorSpeed) \(sysInfo.processorName)\"",
                                            "\"\(sysInfo.ram)\"",
                                            "\"\(graphicsInfo)\"",
                                            "\"\(session.resolution?.text ?? "")\"",
                                            "\"\(session.graphicsSetting ?? "")\"",
                                            "\"\(numFormatter.string(from: NSNumber(value: session.sampleAverage)) ?? "")\"" ]
            report = "\"Summary\"\n"
            report += summaryHeaders.joined(separator: sep) + "\n"
            report += summaryData.joined(separator: sep) + "\n\n"
            
            report += sysInfo.generateCSVReportString()
        }
        if report != "" { report += "\n\n" }
        report += session.generateCSVReportString(game: game)
        
        if !preLoaded { session.releaseSamples() }
        
        return report
    }
    
    func detachFromApp(restartTracer: Bool = false) {
        if !isRestarting {
            isRestarting = restartTracer
            app!.tracer.terminateHelper()
            app!.fps.terminateHelper()
            DispatchQueue.main.async(execute: { [unowned self] () in
                if restartTracer && self.app!.tracer.activeGame != nil && self.app!.tracer.activeGame!.isRunning {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: { [unowned self] in
                        self.app!.tracer.attachToGame(game: self.app!.tracer.activeGame!)
                    })
                }
                else {
                    self.progress.stopAnimation(self)
                    if let activeGame = self.app?.tracer.activeGame {
                        self.app!.mainWindow.table.setGameStatus(game: activeGame, status: "Stop")
                    }
                    self.toolbar.updateIcons(game: self.app!.mainWindow.table.selectedGame)
                    let autoStop = UserDefaults.standard.bool(forKey: "MLAutoStop")
                    if !autoStop && self.app!.tracer.waitingFor != nil {
                        self.toolbar.waitForGameToLaunch(game: self.app!.tracer.waitingFor!)
                    }
                    if autoStop && self.app!.tracer.activeSession != nil {
                        self.app!.tracer.endSession()
                    }
                    self.app!.tracer.activeGame = nil
                }
            })
            if isRestarting {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: { [unowned self] in
                    self.isRestarting = false
                })
            }
        }
    }
    
    func updateGraphSession() {
        DispatchQueue.main.async(execute: { [unowned self] () in
            if let graphView = self.graph.view as? GraphView {
                if graphView.session != nil {
                    graphView.session!.releaseSamples()
                }
                if let session = self.app!.mainWindow!.sessionList.selectedSession {
                    _ = session.loadSamples(directory: self.app!.recordingDirectory)
                    graphView.session = session
                    self.toolbar.shareButton.isEnabled = true
                }
                else {
                    graphView.session = nil
                    self.toolbar.shareButton.isEnabled = false
                }
                graphView.setNumberPrecision()
                graphView.content.needsDisplay = true
                graphView.needsDisplay = true
            }
        })
    }
    
    func runAddNewAsModal(type: String) {
        if type == "Service" {activeSheet = SelectServiceSheet(windowNibName: NSNib.Name(rawValue: "SelectServiceSheet")) }
        else { activeSheet = AddNewSheet(windowNibName: NSNib.Name(rawValue: "AddNewSheet")) }
        if activeSheet != nil {
            activeSheetType = type
            window!.beginSheet(activeSheet!.window!, completionHandler: { [unowned self] (response:NSApplication.ModalResponse) in
                self.activeSheetResponse = response
            })
        }
    }
    
    func windowDidEndSheet(_ notification:Notification) {
        if activeSheetResponse == NSApplication.ModalResponse.OK {
            if activeSheetType != nil && activeSheetType != "Complete" { runAddNewAsModal(type: activeSheetType!) }
            else {
                _ = table.reload()
                activeSheet = nil
                activeSheetType = nil
                app!.tracer.checkAndAttachToGame()
            }
        }
        else {
            activeSheet = nil
            activeSheetType = nil
        }
    }
    
    func showAttachToProcessSheet() {
        if activeSheet != nil { return }
        let attachSheet = AttachToProcessSheet(windowNibName: NSNib.Name(rawValue: "AttachToProcessSheet"))
        activeSheet = attachSheet
        window!.beginSheet(attachSheet.window!) { [unowned self] (response: NSApplication.ModalResponse) in
            guard response == NSApplication.ModalResponse.OK, let sheet = self.activeSheet as? AttachToProcessSheet, let newGame = sheet.game else { return }
            self.activeSheet = nil
            self.app!.checkToAddGameToCollection(game: newGame)
            _ = self.table.reload()
            self.app!.tracer.attachToGame(game: newGame)
            self.table.selectGame(game: newGame)
        }
    }
    
    func toggleSessions(shouldShowSessions:Bool, completion callback: (()->Void)?) {
        if isFullscreen {
            if shouldShowSessions {
                self.toggleSessionViews(shouldShowSessions: true)
                performSessionFade(shouldShowSessions: true, completion: {
                    if callback != nil { callback!() }
                })
            }
            else {
                performSessionFade(shouldShowSessions: false, completion: {
                    self.toggleSessionViews(shouldShowSessions: false)
                    if callback != nil { callback!() }
                })
            }
        }
        else {
            if shouldShowSessions {
                performResize(shouldShowSessions: shouldShowSessions, completion: {
                    self.toggleSessionViews(shouldShowSessions: true)
                    self.performSessionFade(shouldShowSessions: true, completion: callback)
                })
            }
            else {
                performSessionFade(shouldShowSessions: shouldShowSessions, completion: {
                    self.performResize(shouldShowSessions: false, completion: callback)
                    self.toggleSessionViews(shouldShowSessions: false)
                })
            }
        }
    }
    
    func performResize(shouldShowSessions: Bool, completion: (()->Void)?) {
        var finalWidth: CGFloat = 0
        if shouldShowSessions {
            for view in splitView.subviews {
                finalWidth += view.frame.width
            }
        }
        else {
            if completedInitialSizing { finalWidth = splitView.subviews[0].frame.width }
            else { finalWidth = CGFloat(UserDefaults.standard.double(forKey: "MLMainWindowWidth")) }
        }
        
        if finalWidth < 300 { finalWidth = 300 }
        let finalRect = NSRect(origin: window!.frame.origin, size: NSSize(width: finalWidth, height: window!.frame.height))
        NSAnimationContext.current.completionHandler = { ()->Void in
            if completion != nil { completion!() }
            self.completedInitialSizing = true
            
        }
        if !completedInitialSizing { NSAnimationContext.current.duration = 0 }
        window!.animator().setFrame(finalRect, display: true)
    }
    
    func performSessionFade(shouldShowSessions: Bool, completion: (()->Void)?) {
        let alpha:CGFloat = shouldShowSessions ? 1.0 : 0.0
        
        NSAnimationContext.current.completionHandler = {
            if completion != nil { completion!() }
            self.completedInitialFading = true
        }
        if !completedInitialFading { NSAnimationContext.current.duration = 0 }
        
        if let graphView = graph.view as? GraphView {
            graphView.content.animator().alphaValue = alpha
            graphView.header.animator().alphaValue = alpha
        }
        sessionList.list.animator().alphaValue = alpha
        sessionList.list.headerView?.animator().alphaValue = alpha
    }
    
    
    func toggleSessionViews(shouldShowSessions:Bool) {
        for i in 1 ..< splitView.subviews.count { splitView.subviews[i].isHidden = !shouldShowSessions }
    }
}





