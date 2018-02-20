//
//  VDFParser.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/23/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class VDFParser: NSObject {
    
    class func decode(url:NSURL)->NSMutableDictionary {
        let activeDict = NSMutableDictionary()
        if let data = NSData(contentsOf: url as URL) {
            if let dataToString = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue) {
                let text = dataToString as String
                var keys: [String] = []
                
                var makingKey = false
                var makingValue = false
                var activeKey = ""
                var activeValue = ""
                
                for char in text {
                    if char == "\"" {
                        if makingKey && !activeKey.isEmpty {
                            makingKey = false
                        }
                        else if makingValue && !activeValue.isEmpty {
                            makingValue = false
                            var mostRecentDict = activeDict
                            
                            for key in keys {
                                mostRecentDict = mostRecentDict[key] as! NSMutableDictionary
                            }
                            mostRecentDict[activeKey] = activeValue
                            activeKey = ""
                            activeValue = ""
                        }
                        else if !makingKey && activeKey.isEmpty && activeValue.isEmpty {
                            makingKey = true
                        }
                        else if !makingValue && !activeKey.isEmpty && activeValue.isEmpty {
                            makingValue = true
                        }
                    }
                    else if char == "{" {
                        makingKey = false
                        makingValue = false
                        var mostRecentDict = activeDict
                        for key in keys {
                            mostRecentDict = mostRecentDict[key] as! NSMutableDictionary
                        }
                        mostRecentDict[activeKey] = NSMutableDictionary()
                        keys += [activeKey]
                        activeKey = ""
                    }
                    else if char == "}" {
                        if keys.count > 0 { keys.removeLast() }
                    }
                    else {
                        if makingKey { activeKey += String(char) }
                        else if makingValue { activeValue += String(char) }
                    }
                }
            }
        }
        return activeDict
    }
}




