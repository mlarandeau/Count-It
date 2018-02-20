//
//  Supportive.swift
//  Count_It
//
//  Created by Michael LaRandeau on 4/19/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class Supportive {
    
    class func alert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.runModal()
    }
    
    class func appendToFile(path:String,data:String) {
        /*if let file = NSFileHandle(forWritingAtPath: path) {
            file.seekToEndOfFile()
            file.writeData("\(data)\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
            file.closeFile()
        }*/
        
    }
}