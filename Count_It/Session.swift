//
//  Session.swift
//  Count_It
//
//  Created by Michael LaRandeau on 6/15/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class Session: NSObject, NSCoding {
    var samples: [Sample] = []
    let samplesIndex: Int
    var dateReferenceSamples: [Sample] = []
    var sampleMax: Double = 0
    var sampleMin: Double?
    var absoluteMax: Double = 0
    var absoluteMin: Double?
    var title: String?
    var systemInformation: SystemInformation?
    var resolution: Resolution?
    var graphicsSetting: String?
    
    var sampleAverage: Double {
        if samples.isEmpty { return 0 }
        
        var sum: Double = 0
        for sample in samples {
            sum += sample.frameRate
        }
        return sum / Double(samples.count)
    }
    
    var start: NSDate? {
        get {
            if dateReferenceSamples.count > 0 {
                return dateReferenceSamples[0].time
            }
            else { return nil }
        }
    }
    
    var end: NSDate? {
        get {
            if dateReferenceSamples.count > 0 {
                return dateReferenceSamples.last!.time
            }
            else { return nil }
        }
    }
    
    var interval: TimeInterval? {
        get {
            if start != nil && end != nil {
                return end!.timeIntervalSince(start! as Date)
            }
            else { return nil }
        }
    }
    
    var formattedRange: String? {
        get {
            let startDate = start
            let endDate = end
            if startDate != nil && endDate != nil {
                let dateFormatter = DateFormatter()
                dateFormatter.locale = NSLocale.current
                dateFormatter.dateStyle = DateFormatter.Style.short
                dateFormatter.timeStyle = DateFormatter.Style.none
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateStyle = DateFormatter.Style.none
                timeFormatter.timeStyle = DateFormatter.Style.medium
                
                let startDateString = dateFormatter.string(from: startDate! as Date)
                let startTimeString = timeFormatter.string(from: startDate! as Date)
                let endDateString = dateFormatter.string(from: endDate! as Date)
                let endTimeString = timeFormatter.string(from: endDate! as Date)
                let totalTime = formatInterval(interval: nil)!
                
                if startDateString == endDateString {
                    return "\(startDateString) \(startTimeString) - \(endTimeString) (\(totalTime))"
                }
                else {
                    return "\(startDateString) \(startTimeString) - \(endDateString) \(endTimeString) (\(totalTime))"
                }
            }
            return nil
        }
    }
    
    var formattedInterval: String? {
        get {
            if let time = interval {
                
                //let minutesDivisor = time % (60 * 60)
                //let secondsDivisor = minutesDivisor % 60
                let minutesDivisor = time.truncatingRemainder(dividingBy: 60 * 60)
                let secondsDivisor = minutesDivisor.truncatingRemainder(dividingBy: 60)
                
                //let hours = Int(floor(time / (60 * 60)))
                //let minutes = Int(floor(minutesDivisor / 60))
                let minutes = Int(time / 60)
                let seconds = Int(floor(secondsDivisor))
                
                //let hoursString = hours < 10 ? "0\(hours)" : String(hours)
                let minutesString = minutes < 10 ? "0\(minutes)" : String(minutes)
                let secondsString = seconds < 10 ? "0\(seconds)" : String(seconds)
                
                //return hoursString + ":" + minutesString + ":" + secondsString
                return minutesString + ":" + secondsString
            }
            else { return nil }
        }
    }
    
    func formatInterval(interval: TimeInterval?)->String? {
        if let time = interval == nil ? self.interval : interval {
            //let minutesDivisor = time % (60 * 60)
            //let secondsDivisor = minutesDivisor % 60
            let minutesDivisor = time.truncatingRemainder(dividingBy: 60 * 60)
            let secondsDivisor = minutesDivisor.truncatingRemainder(dividingBy: 60)
            
            //let hours = Int(floor(time / (60 * 60)))
            let minutes = Int(time / 60)
            let seconds = Int(floor(secondsDivisor))
            
            let minutesString = minutes < 10 ? "0\(minutes)" : String(minutes)
            let secondsString = seconds < 10 ? "0\(seconds)" : String(seconds)

            return minutesString + ":" + secondsString
        }
        else { return nil }
    }
    
    func generateCSVReportString(game: Game)->String {
        let numFormatter = NumberFormatter()
        let precision = 4
        numFormatter.minimumFractionDigits = precision
        numFormatter.maximumFractionDigits = precision
        let locale = NSLocale.autoupdatingCurrent
        let sep = locale.decimalSeparator == "," ? ";" : ","
        let min: Double? = sampleMin
        let max: Double = sampleMax
        let average: Double = sampleAverage
        var samplesList = "\"Frame Rates\"\n"
        for sample in samples {
            samplesList += "\(numFormatter.string(from: NSNumber(value: sample.frameRate))!)\n"
        }
        
        let titleString = title != nil ? title! : ""
        var timeInterval = formattedRange
        if timeInterval == nil { timeInterval = "" }
        var sessionSummary = "\"Game Title\"\(sep)\"\(game.name)\"\n"
        sessionSummary += "\"Recording Title\"\(sep)\"\(titleString)\"\n"
        sessionSummary += "\"Time Interval\"\(sep)\"\(timeInterval!)\"\n"
        
        let resString = resolution != nil ? resolution!.text : ""
        let graphicsString = graphicsSetting != nil ? graphicsSetting! : ""
        var additionalInfo = "\"Resolution\"\(sep)\"\(resString)\"\n"
        additionalInfo += "\"Graphics Preset\"\(sep)\"\(graphicsString)\"\n"
        
        var sampleSummary = "\"Minimum\"\(sep)\"Maximum\"\(sep)\"Average\"\(sep)\n"
        sampleSummary += "\(numFormatter.string(from: NSNumber(value: min!))!)\(sep)\(numFormatter.string(from: NSNumber(value: max))!)\(sep)\(numFormatter.string(from: NSNumber(value: average))!)\n"
        
        return "\(sessionSummary)\n\"Game Settings\"\n\(additionalInfo)\n\"Frame Rate Information (Frames Per Second)\"\n\(sampleSummary)\n\(samplesList)"
    }
    
    func loadSamples(directory: String)->Bool {
        if let loadedSamples = NSKeyedUnarchiver.unarchiveObject(withFile: "\(directory)/\(samplesIndex)") as? [Sample] {
            samples = loadedSamples
            return true
        }
        return false
    }
    
    func releaseSamples() {
        samples.removeAll()
    }
    
    func deleteFile(directory: String) {
        do {
            try FileManager.default.removeItem(atPath: "\(directory)/\(samplesIndex)")
        }
        catch _ {}
    }
    
    func saveSamplesToFile(directory: String) {
        let path = directory + "/\(samplesIndex)"
        NSKeyedArchiver.archiveRootObject(samples, toFile: path)
    }
    
    override init() {
        samplesIndex = Int(NSDate().timeIntervalSince1970 * 1000)
        super.init()
    }
    
    //NSCoding Protocol
    required init?(coder decoder: NSCoder) {
        //samples = decoder.decodeObjectForKey("MLSessionSamples") as! [Sample]
        dateReferenceSamples = decoder.decodeObject(forKey: "MLSessionDateReferenceSamples") as! [Sample]
        sampleMax = decoder.decodeDouble(forKey: "MLSessionSampleMax")
        sampleMin = decoder.decodeDouble(forKey: "MLSessionSampleMin")
        absoluteMax = decoder.decodeDouble(forKey: "MLSessionAbsoluteMax")
        absoluteMin = decoder.decodeDouble(forKey: "MLSessionAbsoluteMin")
        title = decoder.decodeObject(forKey: "MLSessionTitle") as? String
        resolution = decoder.decodeObject(forKey: "MLSessionResolution") as? Resolution
        graphicsSetting = decoder.decodeObject(forKey: "MLSessionGraphicsSetting") as? String
        systemInformation = decoder.decodeObject(forKey: "MLSessionSystemInformation") as? SystemInformation
        samplesIndex = Int(decoder.decodeDouble(forKey: "MLSessionSamplesIndex"))
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        //coder.encodeObject(samples, forKey: "MLSessionSamples")
        coder.encode(dateReferenceSamples, forKey: "MLSessionDateReferenceSamples")
        coder.encode(sampleMax, forKey: "MLSessionSampleMax")
        if sampleMin == nil { sampleMin = sampleMax }
        coder.encode(sampleMin!, forKey: "MLSessionSampleMin")
        coder.encode(absoluteMax, forKey: "MLSessionAbsoluteMax")
        if absoluteMin == nil { absoluteMin = absoluteMax }
        coder.encode(absoluteMin!, forKey: "MLSessionAbsoluteMin")
        coder.encode(title, forKey: "MLSessionTitle")
        coder.encode(resolution, forKey: "MLSessionResolution")
        coder.encode(graphicsSetting, forKey: "MLSessionGraphicsSetting")
        coder.encode(systemInformation, forKey: "MLSessionSystemInformation")
        coder.encode(Double(samplesIndex), forKey: "MLSessionSamplesIndex")
    }
}
