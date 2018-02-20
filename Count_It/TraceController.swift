//
//  TraceController.swift
//  Count_It
//
//  Created by Michael LaRandeau on 4/19/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa
import ServiceManagement

class TraceController: NSObject, TraceControllerProtocol, TraceManagerDelegate {
    
    //Properties
    let maxSamplingRate = 5_000
    var activeGame: Game?
    var waitingFor: Game?
    var activeSession: Session?
    @IBOutlet weak var app: AppDelegate!
    var helperConnection: NSXPCConnection?
    var hotKeyMonitor: AnyObject?
    var isRecording: Bool = false
    
    let locale: NSLocale = NSLocale.autoupdatingCurrent as NSLocale
    let numFormatter: NumberFormatter = NumberFormatter()
    let reportNameDateFormatter = DateFormatter()
    
    private var manager: TraceManager?
    
    var helperName: String? {
        get {
            let appInfo = Bundle.main.infoDictionary!
            let privilegedHelpers = appInfo["SMPrivilegedExecutables"] as! [String:String]
            if privilegedHelpers.count == 1 {
                for key in privilegedHelpers.keys {
                    return key
                }
            }
            return nil
        }
    }
    
    var helperVersion: String? {
        get {
            return Bundle.main.infoDictionary!["MLTraceHelperVersion"] as? String
        }
    }
    
    var useDTrace: Bool {
        return UserDefaults.standard.bool(forKey: "MLShouldUseDTrace")
    }
    
    //Methods
    override init() {
        super.init()
        
        numFormatter.locale = locale as Locale!
        numFormatter.numberStyle = NumberFormatter.Style.decimal
        
        reportNameDateFormatter.locale = locale as Locale!
        reportNameDateFormatter.dateFormat = "yyyy-MM-dd HHmmss"
        
        NSWorkspace.shared.addObserver(self, forKeyPath: "runningApplications", options: [], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "runningApplications" {
            if activeGame == nil {
                if waitingFor != nil {
                    if waitingFor!.isRunning { app!.mainWindow.toolbar.launchOrAttachToGame(game: waitingFor!) }
                }
                else { checkAndAttachToGame() }
            }
        }
    }
    
    func blessHelper()->Bool {
        if !helperIsBlessed() {
            if !installHelper() {
                return false
            }
        }
        return true
    }
    
    func helperIsBlessed()->Bool {
        if helperName != nil {
            let installedHelperInfo = NSDictionary(contentsOfFile: "/Library/LaunchDaemons/\(helperName!).plist")
            if installedHelperInfo != nil {
                let installedVersion = installedHelperInfo!.value(forKey: "MLVersion") as? String
                if helperVersion != nil && installedVersion != nil && helperVersion! == installedVersion! { return true }
            }
        }
        return false
    }
    
    func installHelper()->Bool {
        /**Install the Helper tool
        /Library/PrivilegedHelperTools
        /Library/LaunchDaemons
        */
        var authRef : AuthorizationRef? = nil
        var status = AuthorizationCreate(nil, nil, [], &authRef)
        
        if Int32(status) != errAuthorizationSuccess {
            Supportive.alert(message: "Error while creating empty authorization.")
            return false
        }
        else {
            var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: nil, flags: 0)
            
            var authRights = AuthorizationItemSet(count: 1, items: &authItem)
            let authFlags = [[], AuthorizationFlags.interactionAllowed, AuthorizationFlags.preAuthorize, AuthorizationFlags.extendRights]
            if authRef != nil {
                status = AuthorizationCopyRights(authRef!, &authRights, nil, AuthorizationFlags(authFlags), nil)
            }
            
            if Int32(status) != errAuthorizationSuccess {
                if Int32(status) == errAuthorizationCanceled {
                    Supportive.alert(message: "The helper tool is required for the app to work.")
                }
                else {
                    Supportive.alert(message: "Action could not be authorized.\nAuthorization Services error code: \(status)")
                }
                return false
            }
            else {
                if helperName == nil { return false }
                else {
                    var error : Unmanaged<CFError>?
                    let blessed = SMJobBless(kSMDomainSystemLaunchd, helperName! as CFString, authRef, &error)
                    if !blessed {
                        Supportive.alert(message: CFErrorCopyDescription(error!.takeRetainedValue()) as String)
                        return false
                        /*Error Codes
                        kSMErrorInternalFailure = 2
                        kSMErrorInvalidSignature = 3
                        kSMErrorAuthorizationFailure = 4
                        kSMErrorToolNotValid = 5
                        kSMErrorJobNotFound = 6
                        kSMErrorServiceUnavailable = 7
                        kSMErrorJobPlistNotFound = 8
                        kSMErrorJobMustBeEnabled = 9
                        kSMErrorInvalidPlist = 10
                        */
                    }
                }
            }
        }
        return true
    }
    
    func checkAndAttachToGame() {
        if UserDefaults.standard.bool(forKey: "MLAutoStart") {
            for game in app!.games.orderedCollection {
                if game.isRunning {
                    app!.mainWindow.toolbar.launchOrAttachToGame(game: game)
                }
            }
        }
    }
    
    func connectToHelper() {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Connect to trace helper.")
        helperConnection = NSXPCConnection(machServiceName: helperName!, options: NSXPCConnection.Options.privileged)
        if helperConnection != nil {
            helperConnection!.exportedInterface = NSXPCInterface(with: TraceControllerProtocol.self)
            helperConnection!.exportedObject = self
            helperConnection!.interruptionHandler = { [unowned self] () in self.app.mainWindow.detachFromApp(restartTracer: true) }
            helperConnection!.invalidationHandler = { [unowned self] () in self.app.mainWindow.detachFromApp() }
            helperConnection!.remoteObjectInterface = NSXPCInterface(with: AppTracerProtocol.self)
            helperConnection!.resume()
        }
    }
    
    func attachToGame(game: Game, pid: pid_t) {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Attach to \(String(describing: game.url))")
        UserDefaults.standard.synchronize()
        let defaults = UserDefaults.standard
        if helperConnection == nil {
            connectToHelper()
            manager?.detach()
            if !useDTrace {
                manager = TraceManager(samplingRate: defaults.integer(forKey: "MLSamplingRate"))
                manager?.delegate = self
                manager?.attach(toPID: pid)
            }
        }
        if helperConnection != nil {
            if defaults.bool(forKey: "MLRecordingAutoStart") { startSession() }
            if defaults.bool(forKey: "MLRecordingAllowHotKey") && hotKeyMonitor == nil { listenForRecordingHotKey() }
            let samplingRate = String(defaults.integer(forKey: "MLSamplingRate")) + "ms"
            let options = ["Sampling Rate" : samplingRate];
            (helperConnection!.remoteObjectProxy as? AppTracerProtocol)?.attach(toApp: pid, options: options, usingDTrace: useDTrace)
            activeGame = game
            if defaults.bool(forKey: "MLAutoStop") { waitingFor = nil }
            else { waitingFor = game }
        }
    }
    
    func attachToGame(game: Game) {
        if game.pid != nil {
            attachToGame(game: game, pid: game.pid!)
        }
    }
    
    func terminateHelper() {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Terminate trace helper.")
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).shouldTerminate()
            helperConnection!.invalidate()
            helperConnection = nil
            manager?.detach()
            stopListeningForHotKey()
            endSession()
        }
    }
    
    func updateSamplingRate(samplingRate:Int) {
        (helperConnection?.remoteObjectProxy as? AppTracerProtocol)?.updateOptions(["Sampling Rate":"\(samplingRate)ms"])
        manager?.samplingRate = samplingRate
    }
    
    func listenForRecordingHotKey() {
        if hotKeyMonitor == nil {
            hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.keyUp, handler: {[unowned self] (event:NSEvent!) in
                if let key = (event.charactersIgnoringModifiers as NSString?)?.uppercased {
                    if let hotKey = (UserDefaults.standard.string(forKey: "MLRecordingHotKey") as NSString?)?.uppercased {
                        if key == hotKey {
                            let flags = event.modifierFlags.intersection((NSEvent.ModifierFlags.option.union(NSEvent.ModifierFlags.command)))
                            if flags == (NSEvent.ModifierFlags.option.union(NSEvent.ModifierFlags.command)) {
                                if self.isRecording { self.endSession() }
                                else { self.startSession() }
                            }
                        }
                    }
                }
            }) as AnyObject?
        }
    }
    
    func stopListeningForHotKey() {
        if hotKeyMonitor != nil {
            NSEvent.removeMonitor(hotKeyMonitor!)
            hotKeyMonitor = nil
        }
    }
    
    func startSession() {
        if activeSession != nil {
            endSession()
        }
        app!.retrieveSystemInformation()
        activeSession = Session()
        isRecording = true
        setFPSColors(backgroundKey: "MLRecordingBackgroundColor", fontKey: "MLRecordingFontColor", checkRecording: true)
        app!.fps.toggleIsRecording(shouldRecord: isRecording);
    }
    
    func endSession() {
        if activeSession != nil && activeSession!.samples.count > 0 {
            if app.sysInfo != nil {                
                activeSession!.systemInformation = app.sysInfo!.copy() as? SystemInformation
            }
            activeGame!.sessions += [activeSession!]
            
            if UserDefaults().bool(forKey: "MLRecordingShouldAutoExport") {
                exportReport(game: activeGame!, session: activeSession!)
            }
            if app.mainWindow.table.selectedGame == activeGame {
                let selectedSessionIndex = app!.mainWindow.sessionList.list.selectedRowIndexes
                app!.mainWindow.sessionList.list.reloadData()
                app!.mainWindow.sessionList.list.selectRowIndexes(selectedSessionIndex, byExtendingSelection: false)
            }
            activeSession!.dateReferenceSamples += [activeSession!.samples[0], activeSession!.samples.last!]
            activeSession!.saveSamplesToFile(directory: app.recordingDirectory)
            activeSession!.releaseSamples()
            app.saveCollection()
            
        }
        activeSession = nil
        isRecording = false
        setFPSColors(backgroundKey: "MLFPSBackgroundColor", fontKey: "MLFPSFontColor", checkRecording: false)
        app!.fps.toggleIsRecording(shouldRecord: isRecording)
    }
    
    func exportReport(game: Game, session: Session) {
        let report = app!.mainWindow!.generateReport(session: session, game: game)
        createAndSaveFile(dataString: report, game: game)
    }
    
    func createAndSaveFile(dataString: String, game: Game) {
        let fileManager = FileManager()
        if let exportSaveDirectory = UserDefaults.standard.string(forKey: "MLRecordingSaveDirectory") {
            var isDirectory = ObjCBool(true)
            if  !fileManager.fileExists(atPath: exportSaveDirectory, isDirectory: &isDirectory) {
                do {
                    try fileManager.createDirectory(atPath: exportSaveDirectory, withIntermediateDirectories: true, attributes: nil)
                } catch _ {
                }
            }
            let gameDirectory = "/" + exportSaveDirectory + "/" + game.name
            if  !fileManager.fileExists(atPath: gameDirectory, isDirectory: &isDirectory) {
                do {
                    try fileManager.createDirectory(atPath: gameDirectory, withIntermediateDirectories: true, attributes: nil)
                } catch _ {
                }
            }
            let now = reportNameDateFormatter.string(from: NSDate(timeIntervalSinceNow: 0) as Date)
            let sessionFilePath = "\(gameDirectory)/\(game.name) \(now).csv"
            _ = fileManager.createFile(atPath: sessionFilePath, contents: nil, attributes: nil)
            if let file = FileHandle(forWritingAtPath: sessionFilePath) {
                file.write(dataString.data(using: String.Encoding.utf8, allowLossyConversion: false)!)
                file.closeFile()
            }
        }
    }
    
    func setFPSColors(backgroundKey:String, fontKey:String, checkRecording:Bool) {
        let defaults = UserDefaults.standard
        if let backgroundColorData = defaults.data(forKey: backgroundKey) {
            if let backgroundColor = NSUnarchiver.unarchiveObject(with: backgroundColorData) as? NSColor {
                self.app!.fps.updateBackgroundColor(color: backgroundColor, checkRecording: checkRecording)
            }
        }
        if let fontColorData = defaults.data(forKey: fontKey) {
            if let fontColor = NSUnarchiver.unarchiveObject(with: fontColorData) as? NSColor {
                self.app!.fps.updateFontColor(color: fontColor, checkRecording: checkRecording)
            }
        }
        
    }
    
    // - MARK: TraceManagerDelegate
    func traceManger(_ traceManager: TraceManager, didReceive data: [Int]) {
        var dataAsString = ""
        for frameRate in data {
            if dataAsString != "" { dataAsString += "\n" }
            dataAsString += String(frameRate)
        }
        handleTraceOutput(dataAsString)
    }
    
    func traceManagerDidDetach(_ traceManager: TraceManager) {
        if helperConnection == nil {
            manager = nil
        }
    }
    
    //TraceControllerProtocol Methods
    func handleTraceOutput(_ data: String!) {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Trace output: \(data)")
        var sum: Double = 0
        var count: Double = 0
        let frames = (data as NSString).components(separatedBy: "\n")
        for frame in frames {
            if let time = Int(frame) {
                let frameTime = Double(time)
                if activeSession != nil {
                    let frameFPS = convertToFPS(time: frameTime)
                    if frameFPS > activeSession!.absoluteMax {
                        activeSession!.absoluteMax = frameFPS
                    }
                    if (activeSession!.absoluteMin == nil || frameFPS < activeSession!.absoluteMin!) && frameFPS >= 0 {
                        activeSession!.absoluteMin = frameFPS
                    }
                }
                sum += frameTime
                count += 1
            }
        }
        if count > 0 && sum > 0 {
            let precision = UserDefaults.standard.integer(forKey: "MLDecimalPrecision")
            let frameRate: Double = convertToFPS(time: (sum / count))
            if activeSession != nil && isRecording {
                if frameRate > activeSession!.sampleMax { activeSession!.sampleMax = frameRate }
                if (activeSession!.sampleMin == nil || frameRate < activeSession!.sampleMin!) && frameRate >= 0.0 {
                    activeSession!.sampleMin = frameRate
                }
                activeSession!.samples += [Sample(frameRate: frameRate,count: Int(count))]
            }
            numFormatter.minimumFractionDigits = precision
            numFormatter.maximumFractionDigits = precision
            app.fps.updateFrameRate(frameRate: numFormatter.string(from: NSNumber(value: frameRate))!)
        }
    }
    
    func convertToFPS(time: Double)->Double {
        return 1000 / (time / 1000000)
    }
    
    func launchFPSHelper() {
        DispatchQueue.main.async(execute: { [unowned self] () in
            self.app.fps.launchHelper()
        })
    }
    
    func giveFPSEndpoint(_ endpoint: NSXPCListenerEndpoint!) {
        app.fps.connect(toHelper: endpoint)
        //app.fps.connectToHelper(endpoint)
    }
    
    func errorHandler(_ error: String) {
        Supportive.alert(message: String(error))
    }
}
