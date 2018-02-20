//
//  Sample.swift
//  Count_It
//
//  Created by Michael LaRandeau on 6/16/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Foundation


class Sample: NSObject, NSCoding {
    var frameRate: Double = 0
    var count: Int = 0
    let time: NSDate
    
    init(frameRate: Double, count: Int) {
        self.frameRate = frameRate
        self.count = count
        time = NSDate()
        
        super.init()
    }
    
    //NSCoding Protocol
    required init?(coder decoder: NSCoder) {
        frameRate = decoder.decodeDouble(forKey: "MLSampleFrameRate")
        count = Int(decoder.decodeInt64(forKey: "MLSampleCount"))
        time = decoder.decodeObject(forKey: "MLSampleTime") as! NSDate
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(frameRate, forKey: "MLSampleFrameRate")
        coder.encode(Int64(count), forKey: "MLSampleCount")
        coder.encode(time, forKey: "MLSampleTime")
    }
}
