//
//  PreferenceController.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/30/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class PreferenceController: NSWindowController, NSToolbarDelegate {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    @IBOutlet var tabView: NSTabView!
    @IBOutlet var toolbar: NSToolbar!
    
    //General
    @IBOutlet var samplingRate: NSSlider!
    @IBOutlet var decimalPrecision: NSPopUpButton!
    @IBOutlet var autoStart: NSButton!
    @IBOutlet var autoStop: NSButton!
    @IBOutlet var saveDirectory: NSTextField!
    @IBOutlet var changeSaveDirectory: NSButton!
    
    //FPS Display
    @IBOutlet var displayBackgroundColor: NSColorWell!
    @IBOutlet var fontSize: NSTextField!
    @IBOutlet var fontSizeStepper: NSStepper!
    @IBOutlet var fontColor: NSColorWell!
    @IBOutlet var fontName: NSPopUpButton!
    @IBOutlet var useRoundedCorners: NSButton!
    @IBOutlet var screenPosition: NSMatrix!
    
    //Recording
    @IBOutlet var recordingAutoStart: NSButton!
    @IBOutlet var recordingAllowHotKey: NSButton!
    @IBOutlet var recordingHotKey: NSTextField!
    @IBOutlet var recordingAutoExport: NSButton!
    @IBOutlet var recordingDirectory: NSTextField!
    @IBOutlet var recordingChangeDirectory: NSButton!
    @IBOutlet var recordingShouldChangeColor: NSButton!
    @IBOutlet var recordingBackgroundColor: NSColorWell!
    @IBOutlet var recordingFontColor: NSColorWell!
    @IBOutlet var recordingShowButton: NSButton!
    
    //Advanced
    @IBOutlet var enableDTrace: NSButton!
    

    override func windowDidLoad() {
        super.windowDidLoad()
        
        setColorPanelProperties()
        
        toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: "GeneralPreferences")
        
        let systemFontItem = NSMenuItem()
        systemFontItem.title = "Default"
        systemFontItem.representedObject = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        fontName.menu?.addItem(systemFontItem)
        
        let allFonts = NSFontManager.shared.availableFontFamilies
        for availableFontName in allFonts {
            if let font = NSFont(name: availableFontName, size: NSFont.systemFontSize) {
                let fontItem = NSMenuItem()
                fontItem.title = font.displayName != nil ? font.displayName! : font.fontName
                fontItem.representedObject = font
                fontName.menu?.addItem(fontItem)
            }
        }
        if let allFontItems = fontName.menu?.items {
            if let defaultFontName = UserDefaults.standard.string(forKey: "MLFPSFont") {
                for item in allFontItems {
                    if let repFont = item.representedObject as? NSFont {
                        if repFont.fontName == defaultFontName {
                            fontName.select(item)
                            break
                        }
                    }
                }
            }
        }
        
        setDefaults()
    }
    
    //Window Methods
    func selectTab(identifier:String) {
        for item in toolbar.items {
            if item.itemIdentifier.rawValue == identifier {
                toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(rawValue: identifier)
                selectTabView(sender: item)
                break
            }
        }
    }
    
    @IBAction func selectTabView(sender: NSToolbarItem) {
        tabView.selectTabViewItem(withIdentifier: sender.itemIdentifier)
        var frameSize: NSSize?
        if sender.itemIdentifier.rawValue == "GeneralPreferences" {
            frameSize = NSSize(width: 520, height: 240)
        }
        else if sender.itemIdentifier.rawValue == "DisplayPreferences" {
            frameSize = NSSize(width: 510, height: 220)
        }
        else if sender.itemIdentifier.rawValue == "RecordingPreferences" {
            frameSize = NSSize(width: 620, height: 285)
        }
        else if sender.itemIdentifier.rawValue == "AdvancedPreferences" {
            frameSize = NSSize(width: 500, height: 250)
        }
        if frameSize != nil {
            let newOrigin = NSPoint(x: window!.frame.origin.x, y: window!.frame.origin.y - (frameSize!.height - window!.contentView!.frame.size.height))
            let frame = NSRect(origin: newOrigin, size: frameSize!)
            let finalFrame = window!.frameRect(forContentRect: frame)
            window!.setFrame(finalFrame, display: true, animate: true)
        }
    }
    
    //General Methods    
    @IBAction func changeSamplingRate(sender: NSSlider) {
        app!.tracer.updateSamplingRate(samplingRate: sender.integerValue)
        UserDefaults.standard.set(sender.integerValue, forKey: "MLSamplingRate")
    }
    
    @IBAction func changeDecimalPrecision(sender: NSPopUpButton) {
        app!.fps.updateDecimalPrecision(precision: sender.selectedTag())
        UserDefaults.standard.set(sender.selectedTag(), forKey: "MLDecimalPrecision")
        app!.mainWindow.updateGraphSession()
    }
    
    @IBAction func changeAutoStart(sender:NSButton) {
        var state = false
        if sender.state.rawValue > 0 { state = true }
        UserDefaults.standard.set(state, forKey: "MLAutoStart")
        app!.tracer.checkAndAttachToGame()
    }
    
    @IBAction func changeAutoStop(sender:NSButton) {
        var state = false
        if sender.state.rawValue > 0 { state = true }
        UserDefaults.standard.set(state, forKey: "MLAutoStop")
    }
    
    @IBAction func changeRootSaveDirectory(sender: NSButton) {
        let open = NSOpenPanel()
        open.canChooseFiles = false
        open.canChooseDirectories = true
        open.prompt = "Select"
        open.beginSheetModal(for: window!, completionHandler: {(response: NSApplication.ModalResponse) in
            if response == NSApplication.ModalResponse.OK {
                if let selectedPath = open.url?.path {
                    let path = (selectedPath + "/" + (Bundle.main.infoDictionary!["CFBundleName"] as! String)) as NSString
                    let fileManager = FileManager.default
                    do {
                        try fileManager.moveItem(atPath: self.app!.rootSaveDirectory, toPath: path as String)
                        UserDefaults.standard.set(path, forKey: "MLRootSaveDirectory")
                        self.saveDirectory.stringValue = path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
                        self.saveDirectory.toolTip = path as String
                        self.app!.updateRootSaveDirectory(basePath: path as String)
                    }
                    catch {
                        let theError = error as NSError
                        Supportive.alert(message: "\(theError.localizedDescription)\n\nThe action was canceled.")
                    }
                }
            }
        })
    }
    
    //FPS Display Methods
    func setColorPanelProperties() {
        let colorPanel = NSColorPanel.shared
        colorPanel.setTarget(self)
        colorPanel.setAction(#selector(PreferenceController.changeFPSColor(sender:)))
        colorPanel.showsAlpha = true
    }
    
    @objc func changeFPSColor(sender: AnyObject?) {
        if let colorPanel = sender as? NSColorPanel {
            let colorData = NSArchiver.archivedData(withRootObject: colorPanel.color)
            if displayBackgroundColor.isActive {
                app!.fps.updateBackgroundColor(color: colorPanel.color,checkRecording: false)
                UserDefaults.standard.set(colorData, forKey: "MLFPSBackgroundColor")
            }
            else if fontColor.isActive {
                app!.fps.updateFontColor(color: colorPanel.color,checkRecording: false)
                UserDefaults.standard.set(colorData, forKey: "MLFPSFontColor")
            }
            else if recordingBackgroundColor.isActive {
                app!.fps.updateBackgroundColor(color: colorPanel.color, checkRecording: true)
                app!.fps.updateRecordBackgroundColor(color: colorPanel.color)
                UserDefaults.standard.set(colorData, forKey: "MLRecordingBackgroundColor")
            }
            else if recordingFontColor.isActive {
                app!.fps.updateFontColor(color: colorPanel.color, checkRecording: true)
                app!.fps.updateRecordBorderColor(color: colorPanel.color)
                UserDefaults.standard.set(colorData, forKey: "MLRecordingFontColor")
            }
        }

    }
    
    @IBAction func stepFontSize(sender:NSStepper) {
        fontSize.intValue = sender.intValue
        updateFontSize(sender: sender)
    }
    
    @IBAction func changeFontSize(sender:NSTextField) {
        let minSize: Int32 = 10;
        let maxSize: Int32 = 500;
        if sender.intValue > maxSize { sender.intValue = maxSize }
        else if sender.intValue < minSize { sender.intValue = minSize }
        fontSizeStepper.intValue = sender.intValue
        updateFontSize(sender: sender)
    }
    
    func updateFontSize(sender:NSControl) {
        UserDefaults.standard.set(Int(sender.intValue), forKey: "MLFPSFontSize")
        app!.fps.updateFontSize(height: sender.doubleValue)
    }
    
    @IBAction func changeFontName(sender:NSPopUpButton) {
        if let selectedFont = sender.selectedItem?.representedObject as? NSFont {
            UserDefaults.standard.set(selectedFont.fontName, forKey: "MLFPSFont")
            app!.fps.updateFontName(name: selectedFont.fontName)
        }
    }
    
    @IBAction func changeRoundedCorners(sender:NSButton) {
        let shouldRoundCorners = sender.state == .on ? true : false
        UserDefaults.standard.set(shouldRoundCorners, forKey: "MLFPSUseRoundedCorners")
        app!.fps.updateRoundedCorners(shouldUseRoundedCorners: shouldRoundCorners)
    }
    
    
    @IBAction func changeScreenPosition(sender:NSMatrix) {
        if let position = sender.selectedCell()?.tag {
            UserDefaults.standard.set(position, forKey: "MLFPSScreenPosition")
            app!.fps.updateScreenPosition(position: position)
        }
    }
    
    //Recording Preferences
    @IBAction func changeRecordingAutoStart(sender: NSButton) {
        let shouldAutoStart = sender.state == .on ? true : false
        
        let defaults = UserDefaults.standard
        defaults.set(shouldAutoStart, forKey: "MLRecordingAutoStart")
        
        if shouldAutoStart { app!.tracer.startSession() }
    }
    
    @IBAction func changeRecordingAllowHotKey(sender: NSButton) {
        let canUseHotKey = sender.state == .on ? true : false
        if canUseHotKey {
            recordingHotKey.isEnabled = true
            verifyAccessibilityAllowed()
            if app!.tracer.activeGame != nil {
                app!.tracer.listenForRecordingHotKey()
            }
        }
        else {
            recordingHotKey.isEnabled = false
            app!.tracer.stopListeningForHotKey()
        }
        UserDefaults.standard.set(canUseHotKey, forKey: "MLRecordingAllowHotKey")
    }
    
    @IBAction func changeHotKey(sender: NSTextField) {
        sender.stringValue = (sender.stringValue as NSString).uppercased
        UserDefaults.standard.set(sender.stringValue, forKey: "MLRecordingHotKey")
    }
    
    @IBAction func changeShowRecordingButton(sender: NSButton) {
        let show = sender.state == .on ? true : false;
        UserDefaults.standard.set(show, forKey: "MLRecordingShowToggleButton")
        app!.fps.toggleShowRecordButton(shouldShow: show)
    }
    
    @IBAction func changeSaveDirectory(sender: NSButton) {
        let open = NSOpenPanel()
        open.canChooseFiles = false
        open.canChooseDirectories = true
        open.prompt = "Select"
        open.beginSheetModal(for: window!, completionHandler: { [unowned self] (response:NSApplication.ModalResponse) in
            if response == NSApplication.ModalResponse.OK {
                if let selectedPath = open.url?.path {
                    let path = (selectedPath + "/" + (Bundle.main.infoDictionary!["CFBundleName"] as! String)) as NSString
                    UserDefaults.standard.set(path, forKey: "MLRecordingSaveDirectory")
                    self.recordingDirectory.stringValue = path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
                    self.recordingDirectory.toolTip = path as String
                }
            }
        })
    }
    
    @IBAction func changeShouldColorChange(sender:NSButton) {
        let shouldChangeColor = sender.state == .on ? true : false
        
        UserDefaults.standard.set(shouldChangeColor, forKey: "MLRecordingShouldChangeColor")
        
        if app!.tracer.activeGame != nil && app!.tracer.isRecording {
            var backgroundKey: String
            var fontKey: String
            var check: Bool
            if shouldChangeColor {
                backgroundKey = "MLRecordingBackgroundColor"
                fontKey = "MLRecordingFontColor"
                check = true
            }
            else {
                backgroundKey = "MLFPSBackgroundColor"
                fontKey = "MLFPSFontColor"
                check = false
            }
            if let defaultBackgroundColor = UserDefaults.standard.data(forKey: backgroundKey) {
                app!.fps.updateBackgroundColor(color: NSUnarchiver.unarchiveObject(with: defaultBackgroundColor) as! NSColor, checkRecording: check)
            }
            if let defaultFontColor = UserDefaults.standard.data(forKey: fontKey) {
                app!.fps.updateFontColor(color: NSUnarchiver.unarchiveObject(with: defaultFontColor) as! NSColor, checkRecording: check)
            }
        }
    }
    
    @IBAction func changeShouldAutoExport(sender:NSButton) {
        let shouldAutoExport = sender.state == .on ? true : false
        if shouldAutoExport {
            recordingDirectory.isEnabled = true
            recordingChangeDirectory.isEnabled = true
        }
        else {
            recordingDirectory.isEnabled = false
            recordingChangeDirectory.isEnabled = false
        }
        UserDefaults.standard.set(shouldAutoExport, forKey: "MLRecordingShouldAutoExport")
    }
    
    //Advanced Methods
    @IBAction func changeDTraceIsEnabled(sender:NSButton) {
        let state = sender.state.rawValue > 0 ? true : false
        UserDefaults.standard.set(state, forKey: "MLShouldUseDTrace")
    }
    
    //Controller Methods
    func setDefaults() {
        let defaults = UserDefaults.standard
        //General
        samplingRate.integerValue = defaults.integer(forKey: "MLSamplingRate")
        changeSamplingRate(sender: samplingRate)
        
        decimalPrecision.selectItem(withTag: defaults.integer(forKey: "MLDecimalPrecision"))
        
        autoStart.state = NSControl.StateValue(rawValue: defaults.bool(forKey: "MLAutoStart") ? 1 : 0)
        autoStop.state = NSControl.StateValue(rawValue: defaults.bool(forKey: "MLAutoStop") ? 1 : 0)
        
        if let savedRootSaveDirectory = defaults.object(forKey: "MLRootSaveDirectory") as? NSString {
            self.saveDirectory.stringValue = savedRootSaveDirectory.replacingOccurrences(of: NSHomeDirectory(), with: "~")
            self.saveDirectory.toolTip = savedRootSaveDirectory as String
        }
        
        //FPS Display
        let defaultFontSize = defaults.integer(forKey: "MLFPSFontSize")
        fontSize.intValue = Int32(defaultFontSize)
        fontSizeStepper.intValue = Int32(defaultFontSize)

        if let defaultFPSBackgroundColor = defaults.data(forKey: "MLFPSBackgroundColor") {
            displayBackgroundColor.color = NSUnarchiver.unarchiveObject(with: defaultFPSBackgroundColor) as! NSColor
        }
        if let defaultFPSFontColor = defaults.data(forKey: "MLFPSFontColor") {
            fontColor.color = NSUnarchiver.unarchiveObject(with: defaultFPSFontColor) as! NSColor
        }
        if defaults.bool(forKey: "MLFPSUseRoundedCorners") {
            useRoundedCorners.state = .on
        }
        else {
            useRoundedCorners.state = .off
        }
        let defaultScreenPosition = defaults.integer(forKey: "MLFPSScreenPosition")
        screenPosition.selectCell(withTag: defaultScreenPosition)
        defaults.set(defaultScreenPosition, forKey: "MLFPSScreenPosition")
        
        //Recording
        recordingAutoStart.state = defaults.bool(forKey: "MLRecordingAutoStart") ? .on : .off
        
        recordingAllowHotKey.state = defaults.bool(forKey: "MLRecordingAllowHotKey") ? .on : .off
        if recordingAllowHotKey.state == .on { recordingHotKey.isEnabled = true }
        else { recordingHotKey.isEnabled = false }
        
        recordingAutoExport.state = defaults.bool(forKey: "MLRecordingShouldAutoExport") ? .on : .off
        
        let saveDirectory = defaults.string(forKey: "MLRecordingSaveDirectory")! as NSString
        recordingDirectory.stringValue = saveDirectory.replacingOccurrences(of: NSHomeDirectory(), with: "~")
        recordingDirectory.toolTip = saveDirectory as String
        recordingDirectory.isEnabled = recordingAutoExport.state == .on ? true : false
        
        recordingChangeDirectory.isEnabled = recordingAutoExport.state == .on ? true : false
        
        recordingHotKey.stringValue = (defaults.string(forKey: "MLRecordingHotKey")! as NSString).uppercased
        
        recordingShowButton.state = defaults.bool(forKey: "MLRecordingShowToggleButton") ? .on : .off
        
        recordingShouldChangeColor.state = defaults.bool(forKey: "MLRecordingShouldChangeColor") ? .on : .off
        if let defaultRecordingBackgroundColor = defaults.data(forKey: "MLRecordingBackgroundColor") {
            recordingBackgroundColor.color = NSUnarchiver.unarchiveObject(with: defaultRecordingBackgroundColor) as! NSColor
        }
        if let defaultRecordingFontColor = defaults.data(forKey: "MLRecordingFontColor") {
            recordingFontColor.color = NSUnarchiver.unarchiveObject(with: defaultRecordingFontColor) as! NSColor
        }
        
        //Advanced
        enableDTrace.state = NSControl.StateValue(rawValue: defaults.bool(forKey: "MLShouldUseDTrace") ? 1 : 0)
        
        defaults.synchronize()
    }
    
    func verifyAccessibilityAllowed() {
        let optionKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [optionKey:true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    //Class Methods
    class func registerDefaults() {
        let defaults = UserDefaults.standard
        
        //General
        let samplingRate = 1000
        let decimalPrecision = 1
        let autoStart = false
        let autoStop = true
        let rootSaveDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/" + (Bundle.main.infoDictionary!["CFBundleName"] as! String)
        
        //FPS Display
        let fpsBackgroundColor = NSArchiver.archivedData(withRootObject: NSColor.black)
        let fpsFontColor = NSArchiver.archivedData(withRootObject: NSColor.white)
        let fpsFontSize = 25
        let fpsScreenPosition = 6
        let fpsFontName = NSFont.systemFont(ofSize: NSFont.systemFontSize).fontName
        let fpsRoundedCorners = false
        
        
        //Recording
        let recordingShouldAutoStart = false
        let recordingAllowHotKey = false
        let recordingHotKey = "R"
        let recordingSaveDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/" + (Bundle.main.infoDictionary!["CFBundleName"] as! String)
        let recordingChangeColor = false
        let recordingAutoExport = false
        let recordingBackColor = NSArchiver.archivedData(withRootObject: NSColor.red)
        let recordingColorFont = NSArchiver.archivedData(withRootObject: NSColor.white)
        let recordingShowToggleButton = true
        
        //Advanced
        let shouldUseDTrace = false
        
        //Window State
        let displayGraph: NSControl.StateValue = .on
        
        //Alerts
        let suppressMissingDataAlert = false
        
        if !defaults.bool(forKey: "MLHasCheckedAndUpdatedAutoExportPath") {
            if let autoExportPath = defaults.object(forKey: "MLRecordingSaveDirectory") as? String {
                defaults.set(autoExportPath + "/" + (Bundle.main.infoDictionary!["CFBundleName"] as! String), forKey: "MLRecordingSaveDirectory")
            }
            defaults.set(true, forKey: "MLHasCheckedAndUpdatedAutoExportPath")
        }
        if defaults.object(forKey: "MLRecordingShowToggleButton") == nil {
            defaults.set(recordingShowToggleButton, forKey: "MLRecordingShowToggleButton")
        }
        let savedRootSaveDirectory = defaults.object(forKey: "MLRootSaveDirectory") as? String
        if savedRootSaveDirectory == nil || savedRootSaveDirectory == "" {
            defaults.set(rootSaveDirectory, forKey: "MLRootSaveDirectory")
        }
        
        UserDefaults.standard.register(defaults: ["MLRootSaveDirectory":rootSaveDirectory,
                                                                "MLSamplingRate":samplingRate,
                                                                "MLDecimalPrecision":decimalPrecision,
                                                                "MLAutoStart":autoStart,
                                                                "MLAutoStop":autoStop,
                                                                "MLFPSBackgroundColor":fpsBackgroundColor,
                                                                "MLFPSFontColor":fpsFontColor,
                                                                "MLFPSFontSize":fpsFontSize,
                                                                "MLFPSFont":fpsFontName,
                                                                "MLFPSUseRoundedCorners":fpsRoundedCorners,
                                                                "MLFPSScreenPosition":fpsScreenPosition,
                                                                "MLRecordingAutoStart":recordingShouldAutoStart,
                                                                "MLRecordingAllowHotKey":recordingAllowHotKey,
                                                                "MLRecordingHotKey":recordingHotKey,
                                                                "MLRecordingSaveDirectory":recordingSaveDirectory,
                                                                "MLRecordingShouldChangeColor":recordingChangeColor,
                                                                "MLRecordingShouldAutoExport":recordingAutoExport,
                                                                "MLRecordingBackgroundColor":recordingBackColor,
                                                                "MLRecordingFontColor":recordingColorFont,
                                                                "MLRecordingShowToggleButton":recordingShowToggleButton,
                                                                "MLShouldDisplayGraph":displayGraph,
                                                                "MLSuppressMissingDataAlert":suppressMissingDataAlert,
                                                                "MLShouldUseDTrace":shouldUseDTrace])
        if !defaults.bool(forKey: "MLHasPerformedSuccessfulLaunch") {
            defaults.set(fpsScreenPosition, forKey: "MLFPSScreenPosition")
            defaults.set(decimalPrecision, forKey: "MLDecimalPrecision")
            defaults.set(recordingShowToggleButton, forKey: "MLRecordingShowToggleButton")
            defaults.set(displayGraph, forKey: "MLShouldDisplayGraph")
        }
        defaults.synchronize()
    }
}









