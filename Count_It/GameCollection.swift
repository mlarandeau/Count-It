//
//  GameCollection.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/6/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class GameCollection: NSObject {
    
    var orderedCollection : [Game]
    var keyValueCollection : [String:Game]
    
    var count : Int {
        get {
            return orderedCollection.count
        }
    }
    
    subscript(index: Int)->Game {
        get {
            return orderedCollection[index]
        }
    }
    
    subscript(name: String)->Game? {
        get {
            return keyValueCollection[name]
        }
    }
    
    func add(url:NSURL) {
        if let newGame = Game(url: url) {
            add(game: newGame)
        }
    }
    
    func add(game:Game) {
        
        if keyValueCollection[game.name] == nil {
            keyValueCollection[game.name] = game
            orderedCollection += [game]
            orderedCollection.sort {
                let firstName = $0.displayName != nil ? $0.displayName! : $0.name
                let secondName = $1.displayName != nil ? $1.displayName! : $1.name
                
                if firstName.caseInsensitiveCompare(secondName) == ComparisonResult.orderedAscending { return true }
                else { return false }
            }
        }
    }
    
    func remove(name:String) {
        for i in 0 ..< orderedCollection.count {
            if orderedCollection[i].name == name {
                _ = orderedCollection.remove(at: i)
                break
            }
        }
        _ = keyValueCollection.removeValue(forKey: name)
    }
    
    func saveToFile(directory: String) {
        for game in orderedCollection {
            game.saveToFile(directory: directory)
        }
    }
    
    func generate() -> AnyIterator<Game> {
        var index = 0
        return AnyIterator {
            if index < self.orderedCollection.count {
                let selection = self.orderedCollection[index]
                index += 1
                return selection
                //return self.orderedCollection[index++]
            }
            return nil
        }
    }
    
    
    //Initialization
    override init() {
        orderedCollection = []
        keyValueCollection = [:]
        
        super.init()
    }
    
    convenience init(directory:String) {
        self.init()
        if let enumerator = FileManager().enumerator(at: NSURL(fileURLWithPath: directory, isDirectory: true) as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles, errorHandler: nil) {
            var enumObj: AnyObject? = enumerator.nextObject() as AnyObject?
            while enumObj != nil {
                if let url = enumObj as? NSURL {
                    if let path = url.path {
                        if let newGame = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? Game {
                            add(game:newGame)
                        }
                    }
                }
                enumObj = enumerator.nextObject() as AnyObject?
            }
        }
    }
}
