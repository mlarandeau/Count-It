//
//  Resolution.swift
//  Count_It
//
//  Created by Michael LaRandeau on 10/17/15.
//  Copyright © 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class Resolution: NSObject, NSCoding {

    let width: Int
    let height: Int
    
    var text: String {
        get {
            return "\(width) x \(height)"
        }
    }
    
    init(width:Int, height:Int) {
        self.width = width
        self.height = height
        
        super.init()
    }
    
    //NSCoding
    required init?(coder decoder: NSCoder) {
        width = Int(decoder.decodeDouble(forKey: "MLResolutionWidth"))
        height = Int(decoder.decodeDouble(forKey: "MLResolutionHeight"))
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(Double(width), forKey: "MLResolutionWidth")
        coder.encode(Double(height), forKey: "MLResolutionHeight")
    }
}
