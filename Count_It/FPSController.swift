//
//  FPSController.swift
//  Count_It
//
//  Created by Michael LaRandeau on 4/25/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class FPSController: NSObject, FPSControllerProtocol {
    
    @IBOutlet weak var app : AppDelegate!
    var helperConnection : NSXPCConnection?
    
    //Methods
    func launchHelper() {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Launch FPS Helper")
        let helperPath = Bundle.main.resourcePath! + "/MLaRandeau.Count-It-FPSHelper";
        let helperURL = NSURL(fileURLWithPath: helperPath)
        let appPID = NSRunningApplication.current.processIdentifier;
        let appName = NSRunningApplication.current.bundleIdentifier!;
        let args = [NSWorkspace.LaunchConfigurationKey.arguments:[String(appPID),appName]]
        if (try? NSWorkspace.shared.launchApplication(at: helperURL as URL, options: NSWorkspace.LaunchOptions.default, configuration: args)) != nil {
            app!.mainWindow.progress.stopAnimation(self)
            if let activeGame = app?.tracer.activeGame {
                self.app!.mainWindow.table.setGameStatus(game: activeGame, status: "Attached")
            }
        }
    }
    
    func updateFrameRate(frameRate:String) {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Frame rate \(frameRate)")
        if helperConnection != nil { (helperConnection!.remoteObjectProxy as AnyObject).updateFrameRate(frameRate) }
    }
    
    func updateBackgroundColor(color:NSColor,checkRecording: Bool) {
        if helperConnection != nil {
            if !checkRecording || (checkRecording && app!.tracer.isRecording && UserDefaults.standard.bool(forKey: "MLRecordingShouldChangeColor")) {
                (helperConnection!.remoteObjectProxy as AnyObject).updateBackgroundColor(color)
            }
        }
    }
    
    func updateRecordBackgroundColor(color:NSColor) {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).updateRecordButtonFill(color)
        }
    }
    
    func updateFontColor(color:NSColor,checkRecording: Bool) {
        if helperConnection != nil {
            if !checkRecording || (checkRecording && app!.tracer.isRecording && UserDefaults.standard.bool(forKey: "MLRecordingShouldChangeColor")) {
                (helperConnection!.remoteObjectProxy as AnyObject).updateFontColor(color)
            }
        }
    }
    
    func updateRecordBorderColor(color:NSColor) {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).updateRecordButtonBorderColor(color);
        }
    }
    
    func updateFontSize(height:Double) {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).updateFontSize(height)
        }
    }
    
    func updateFontName(name:String) {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).updateFontName(name)
        }
    }
    
    func updateRoundedCorners(shouldUseRoundedCorners:Bool) {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).updateRoundedCorners(shouldUseRoundedCorners)
        }
    }
    
    func updateScreenPosition(position:Int) {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).updateScreenPosition(Int32(position))
        }
    }
    
    func updateDecimalPrecision(precision:Int) {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).updateDecimalPrecision(Int32(precision))
        }
    }
    
    func toggleIsRecording(shouldRecord:Bool) {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).toggleIsRecording(shouldRecord);
        }
    }
    
    func toggleShowRecordButton(shouldShow:Bool) {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).toggleShowRecordButton(shouldShow)
        }
    }
    
    func terminateHelper() {
        if helperConnection != nil {
            (helperConnection!.remoteObjectProxy as AnyObject).shouldTerminate()
            if helperConnection != nil { helperConnection!.invalidate() }
            helperConnection = nil
        }
    }
    
    //FPSControllerProtocol
    func connect(toHelper endpoint: NSXPCListenerEndpoint!) {
        Supportive.appendToFile(path: app!.logFilePath, data: "\(NSDate(timeIntervalSinceNow: 0).description): Connect to FPS Helper")
        helperConnection = NSXPCConnection(listenerEndpoint: endpoint)
        
        if helperConnection != nil {
            helperConnection!.exportedInterface = NSXPCInterface(with: FPSControllerProtocol.self)
            helperConnection!.exportedObject = self
            helperConnection!.invalidationHandler = { [unowned self] () in self.app.mainWindow.detachFromApp() }
            helperConnection!.interruptionHandler = { [unowned self] () in self.app.mainWindow.detachFromApp(restartTracer: true) }
            helperConnection!.remoteObjectInterface = NSXPCInterface(with: AppLinkProtocol.self)
            helperConnection!.resume()
        }
    }
    
    func toggleBaseRecording(_ shouldRecord: Bool) {
        DispatchQueue.main.async(execute: {
            if shouldRecord && !self.app.tracer.isRecording {
                self.app.tracer.startSession();
            }
            else if !shouldRecord && self.app.tracer.isRecording {
                self.app.tracer.endSession();
            }
        })
    }
}
