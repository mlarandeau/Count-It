//
//  SystemInformation.swift
//  Count_It
//
//  Created by Michael LaRandeau on 6/28/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class SystemInformation: NSObject, NSCoding, NSCopying {
    
    let remoteInfoOperationQueue = OperationQueue()
    
    var version: String
    var gpuName: String
    var gpuVRAM: String
    var processorName: String
    var processorSpeed: String
    var processorCores: String
    var computerName: String
    var computerModel: String
    var computerType: String
    var computerSerialNumber: String
    var ram: String
    var resolutions: [Resolution]
    
    var computerYear: String {
        do {
            let regEx = try NSRegularExpression(pattern: "20[0-9]{2}", options: [])
            let range = NSRange(location: 0, length: computerType.count)
            guard let match = regEx.firstMatch(in: computerType, options: [], range: range) else { return "" }
            return (computerType as NSString).substring(with: match.range)
        } catch {
            return ""
        }
    }
    
    var gpuVRAMGB: String {
        guard let gbString = gpuVRAM.components(separatedBy: " ").first, let gb = Double(gbString) else { return "" }
        let gbInt = Int(gb/1024)
        return String(gbInt) + " GB"
    }
    
    class func generateSystemInformationReport(task: Process?, saveToPath: String) {
        FileManager.default.createFile(atPath: saveToPath, contents: nil, attributes: nil)
        if let file = FileHandle(forWritingAtPath: saveToPath) {
            var createSystemReport = task
            if createSystemReport == nil { createSystemReport = Process() }
            createSystemReport!.launchPath = "/usr/sbin/system_profiler"
            createSystemReport!.arguments = ["-detailLevel","basic","SPDisplaysDataType","SPHardwareDataType","-xml"]
            createSystemReport!.standardOutput = file
            createSystemReport!.launch()
        }
    }
    
    override init() {
        //let versionInfo = NSProcessInfo.processInfo().operatingSystemVersion
        //version = "\(versionInfo.majorVersion).\(versionInfo.minorVersion).\(versionInfo.patchVersion)"
        if #available(OSX 10.10, *) {
            let versionParts = ProcessInfo.processInfo.operatingSystemVersion
            version = "\(versionParts.majorVersion).\(versionParts.minorVersion).\(versionParts.patchVersion)"
        } else {
            version = ProcessInfo.processInfo.operatingSystemVersionString
        }
        gpuName = ""
        gpuVRAM = ""
        processorName = ""
        processorSpeed = ""
        processorCores = ""
        computerName = ""
        computerModel = ""
        computerType = ""
        computerSerialNumber = ""
        ram = ""
        
        var possibleResolutions: [Resolution] = []
        if let modes: NSArray = CGDisplayCopyAllDisplayModes(CGMainDisplayID(), nil) {
            for mode in modes {
                let trueMode = mode as! CGDisplayMode
                possibleResolutions += [Resolution(width: trueMode.width, height: trueMode.height)]
            }
        }
        
        resolutions = possibleResolutions
        
        super.init()
    }
    
    convenience init(contentsOfFile filePath: String) {
        self.init()

        if let sysInfo = NSArray(contentsOfFile: filePath) {
            if let allDisplays = (sysInfo[0] as? NSDictionary)?["_items"] as? NSArray {
                for display in allDisplays {
                    if let displayInfo = display as? NSDictionary {
                        if let gpuNameRaw = displayInfo["sppci_model"] as? String {
                            if gpuName != "" { gpuName += ", " }
                            gpuName += gpuNameRaw
                        }
                        if let gpuVRAMRaw = displayInfo["spdisplays_vram"] as? String {
                            if gpuVRAM != "" { gpuVRAM += ", " }
                            gpuVRAM += gpuVRAMRaw
                        }
                    }
                }
            }
            if let hardwareInfo = ((sysInfo[1] as? NSDictionary)?["_items"] as? NSArray)?[0] as? NSDictionary {
                if let processorNameRaw = hardwareInfo["cpu_type"] as? String {
                    processorName = processorNameRaw
                }
                if let processorSpeedRaw = hardwareInfo["current_processor_speed"] as? String {
                    processorSpeed = processorSpeedRaw
                }
                if let coresInt = hardwareInfo["number_processors"] as? Int {
                    processorCores = String(coresInt)
                }
                if let computerNameRaw = hardwareInfo["machine_name"] as? String {
                    computerName = computerNameRaw
                }
                if let ramRaw = hardwareInfo["physical_memory"] as? String {
                    ram = ramRaw
                }
                if let modelRaw = hardwareInfo["machine_model"] as? String {
                    computerModel = modelRaw
                }
                if let serialNumberRaw = hardwareInfo["serial_number"] as? String {
                    computerSerialNumber = serialNumberRaw
                    determineComputerType()
                }
            }
        }
        
        do {
            try FileManager.default.removeItem(atPath: filePath)
        }
        catch _ {}
    }
    
    func generateCSVReportString()->String {
        var report = ""
        
        let locale = NSLocale.autoupdatingCurrent
        let sep = locale.decimalSeparator == "," ? ";" : ","
        report = "\"Computer Details\"\n"
        let computerNameToUse = computerType != "" ? computerType : computerName
        report += "\"Computer:\"\(sep)\"\(computerNameToUse)\"\n"
        report += "\"Model:\"\(sep)\"\(computerModel)\"\n"
        report += "\"OS Version:\"\(sep)\"\(version)\"\n"
        report += "\"Processor:\"\(sep)\"\(processorName)\"\n"
        report += "\"Processor Speed:\"\(sep)\"\(processorSpeed)\"\n"
        report += "\"Processor Core Number:\"\(sep)\"\(processorCores)\"\n"
        report += "\"RAM:\"\(sep)\"\(ram)\"\n"
        report += "\"GPU:\"\(sep)\"\(gpuName)\"\n"
        report += "\"GPU VRAM:\"\(sep)\"\(gpuVRAM)\"\n"
        
        return report
    }
    
    func determineComputerType() {
        if computerSerialNumber.count >= 11 {
            let serialNumParameter = NSString(string: computerSerialNumber).substring(from: 8)
            remoteInfoOperationQueue.addOperation({
                if let infoURL = NSURL(string: "http://support-sp.apple.com/sp/product?cc=\(serialNumParameter)") {
                    do {
                        let remoteXML = try XMLDocument(contentsOf: infoURL as URL, options: XMLNode.Options(rawValue: XMLNode.Options.RawValue(Int(UInt(XMLNode.Options.documentTidyXML.rawValue)))))
                        if let typeNodes = try remoteXML.rootElement()?.nodes(forXPath: "configCode") {
                            if typeNodes.count > 0 {
                                if let remoteTypeString = typeNodes[0].stringValue {
                                    self.computerType = remoteTypeString
                                }
                            }
                        }
                    }
                    catch {}
                }
            })
        }
    }
    
    //NSCoding
    required init?(coder decoder: NSCoder) {
        version = decoder.decodeObject(forKey: "MLSysInfoVersion") as! String
        gpuName = decoder.decodeObject(forKey: "MLSysInfoGPUName") as! String
        gpuVRAM = decoder.decodeObject(forKey: "MLSysInfoGPUVRAM") as! String
        processorName = decoder.decodeObject(forKey: "MLSysInfoProcessorName") as! String
        processorSpeed = decoder.decodeObject(forKey: "MLSysInfoProcessorSpeed") as! String
        processorCores = decoder.decodeObject(forKey: "MLSysInfoProcessorCores") as! String
        computerName = decoder.decodeObject(forKey: "MLSysInfoComputerName") as! String
        ram = decoder.decodeObject(forKey: "MLSysInfoRAM") as! String
        
        if let savedSerialNumber = decoder.decodeObject(forKey: "MLSysInfoSerialNumber") as? String {
            computerSerialNumber = savedSerialNumber
        }
        else { computerSerialNumber = "" }
        
        if let savedModel = decoder.decodeObject(forKey: "MLSysInfoComputerModel") as? String {
            computerModel = savedModel
        }
        else { computerModel = "" }
        
        if let savedType = decoder.decodeObject(forKey: "MLSysInfoComputerType") as? String {
            computerType = savedType
        }
        else { computerType = "" }
        
        let hasResolutions = decoder.decodeObject(forKey: "MLSysInfoResolutions") as? [Resolution]
        if hasResolutions != nil {
            resolutions = hasResolutions!
        }
        else {
            resolutions = []
        }
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(version, forKey: "MLSysInfoVersion")
        coder.encode(gpuName, forKey: "MLSysInfoGPUName")
        coder.encode(gpuVRAM, forKey: "MLSysInfoGPUVRAM")
        coder.encode(processorName, forKey: "MLSysInfoProcessorName")
        coder.encode(processorSpeed, forKey: "MLSysInfoProcessorSpeed")
        coder.encode(processorCores, forKey: "MLSysInfoProcessorCores")
        coder.encode(computerName, forKey: "MLSysInfoComputerName")
        coder.encode(ram, forKey: "MLSysInfoRAM")
        coder.encode(resolutions, forKey: "MLSysInfoResolutions")
        coder.encode(computerSerialNumber, forKey: "MLSysInfoSerialNumber")
        coder.encode(computerModel, forKey:"MLSysInfoComputerModel")
        coder.encode(computerType, forKey: "MLSysInfoComputerType")
    }
    
    //NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let newSysInfo = SystemInformation()
        newSysInfo.version = version
        newSysInfo.gpuVRAM = gpuVRAM
        newSysInfo.gpuName = gpuName
        newSysInfo.processorName = processorName
        newSysInfo.processorSpeed = processorSpeed
        newSysInfo.processorCores = processorCores
        newSysInfo.computerName = computerName
        newSysInfo.ram = ram
        newSysInfo.resolutions = resolutions
        newSysInfo.computerModel = computerModel
        newSysInfo.computerType = computerType
        newSysInfo.computerSerialNumber = computerSerialNumber
        
        return newSysInfo
    }
}




