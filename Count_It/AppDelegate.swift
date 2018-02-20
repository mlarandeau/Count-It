//
//  AppDelegate.swift
//  Count_It
//
//  Created by Michael LaRandeau on 4/12/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let logFilePath = NSHomeDirectory() + "/Desktop/Count_It_LogFile(\(NSDate(timeIntervalSinceNow: 0).description)).txt"
    var rootSaveDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/" + (Bundle.main.infoDictionary!["CFBundleName"] as! String)
    var dataDirectory: String!
    var recordingDirectory: String!
    
    var mainWindow: MainWindow!
    var preferences: PreferenceController?
    @IBOutlet var tracer: TraceController!
    @IBOutlet var fps: FPSController!
    @IBOutlet var menu: MainMenuController!
    var games: GameCollection!
    var sysInfo: SystemInformation?
    var sysInfoTask: Process?
    var reportFilePath: String?
    var sharedFilePath: String?
    var didBlessHelper: Bool = false
    var displayResolutions: [(Int,Int)] = []

    func updateRootSaveDirectory(basePath: String) {
        rootSaveDirectory = basePath
        sharedFilePath = rootSaveDirectory + "/SharedRecording.csv"
        dataDirectory = rootSaveDirectory + "/AppData"
        recordingDirectory = rootSaveDirectory + "/Recordings"
        reportFilePath = rootSaveDirectory + "/systemInformationReport.xml"
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if tracer.blessHelper() {
            PreferenceController.registerDefaults()
            
            TraceManager.cleanUpHelpers()
            
            didBlessHelper = true
            if let savedRootSaveDirectory = UserDefaults.standard.object(forKey: "MLRootSaveDirectory") as? String {
                rootSaveDirectory = savedRootSaveDirectory
            }
            updateRootSaveDirectory(basePath: rootSaveDirectory)
            games = GameCollection(directory: dataDirectory)
            //Can't guarentee that the files weren't moved to another computer
            /*for game in games.orderedCollection {
                for session in game.sessions {
                    if session.systemInformation?.computerType == "" {
                        session.systemInformation?.determineComputerType()
                    }
                }
            }*/
            createSaveLocation()
            
            mainWindow = MainWindow(windowNibName: NSNib.Name(rawValue: "MainWindow"))
            let main = mainWindow!.window
            main!.makeKeyAndOrderFront(self)
            
            tracer.checkAndAttachToGame()
            
            retrieveSystemInformation()
            
            /*if !NSFileManager.defaultManager().fileExistsAtPath(logFilePath) {
                NSFileManager.defaultManager().createFileAtPath(logFilePath, contents: nil, attributes: nil)
            }*/
            
            do {
                try FileManager.default.removeItem(atPath: sharedFilePath!)
            }
            catch _ {}
            UserDefaults.standard.set(true, forKey: "MLHasPerformedSuccessfulLaunch")
        }
        else {
            didBlessHelper = false
            NSApplication.shared.terminate(nil)
        }
    }
    
    func checkToAddGameToCollection(game: Game) {
        if let inCollection = games[game.name] {
            if inCollection.urlBookmark == game.urlBookmark { return }
            let confirm = NSAlert()
            confirm.messageText = "\(game.name) already has already been added.  Would you like to change the file location of \(game.name) to this new location?"
            confirm.addButton(withTitle: "Cancel")
            confirm.addButton(withTitle: "Change Location")
            if confirm.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn {
                if tracer.activeGame != nil && tracer.activeGame!.name == game.name {
                    Supportive.alert(message: "The location of a game cannot be changed while its framerate is being tracked.")
                }
                else {
                    inCollection.url = game.url
                    inCollection.saveToFile(directory: dataDirectory)
                }
            }
        }
        else {
            games.add(game: game)
            game.saveToFile(directory: dataDirectory)
        }
    }
    
    func createSaveLocation() {
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(true)
        if !fileManager.fileExists(atPath: rootSaveDirectory, isDirectory: &isDirectory) {
            do {
                try fileManager.createDirectory(atPath: rootSaveDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch _ {}
        }
        isDirectory = ObjCBool(true)
        if !fileManager.fileExists(atPath: dataDirectory, isDirectory: &isDirectory) {
            do {
                try fileManager.createDirectory(atPath: dataDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch _ {}
        }
        isDirectory = ObjCBool(true)
        if !fileManager.fileExists(atPath: recordingDirectory, isDirectory: &isDirectory) {
            do {
                try fileManager.createDirectory(atPath: recordingDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch _ {}
        }
    }
    
    func retrieveSystemInformation() {
        sysInfoTask = Process()
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.parseSystemReport(notification:)), name: Process.didTerminateNotification, object: sysInfoTask)
        SystemInformation.generateSystemInformationReport(task: sysInfoTask!,saveToPath: reportFilePath!)
    }
    
    @objc func parseSystemReport(notification: NSNotification) {
        if reportFilePath != nil { sysInfo = SystemInformation(contentsOfFile: reportFilePath!) }
        NotificationCenter.default.removeObserver(self, name: Process.didTerminateNotification, object: sysInfoTask)
        sysInfoTask = nil
        if let graphView = mainWindow!.graph.view as? GraphView {
            if sysInfo != nil {
                graphView.header.initializeResolutionPopUp(resolutions: sysInfo!.resolutions)
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            if let menuItem = menu.menu.item(withTitle: "Window")?.submenu?.item(withTitle: "Collection") {
                menuItem.state = .on
            }
            mainWindow.showWindow(nil)
            return false
        }
        return true
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if mainWindow != nil { mainWindow.detachFromApp() }
        if tracer.activeSession != nil { tracer.endSession() }
        if didBlessHelper {
            //saveCollection()
            UserDefaults.standard.synchronize()
        }
        TraceManager.cleanUpHelpers()
        return NSApplication.TerminateReply.terminateNow
    }
    
    func saveCollection() {
        createSaveLocation()
        games.saveToFile(directory: dataDirectory)
    }
    
    @IBAction func showPreferences(sender:AnyObject?) {
        if preferences == nil {
            preferences = PreferenceController(windowNibName: NSNib.Name(rawValue: "PreferenceController"))
            _ = preferences!.window
        }
        preferences!.showWindow(self)
    }
    
    @IBAction func showRecordingPreferences(sender:AnyObject) {
        self.showPreferences(sender: sender)
        preferences?.selectTab(identifier: "RecordingPreferences")
    }
}







