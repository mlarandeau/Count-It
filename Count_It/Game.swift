//
//  Game.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/4/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class Game: NSObject, NSCoding {
    
    private(set) var urlBookmark: Data
    private(set) var name: String
    var displayName: String?
    var sessions: [Session] = []
    
    var url: NSURL? {
        get {
            return try? NSURL(resolvingBookmarkData: urlBookmark, options: [], relativeTo: nil, bookmarkDataIsStale: nil)
        }
        set {
            guard let newURL = newValue else { return }
            guard let bookmark = try? newURL.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil) else { return }
            urlBookmark = bookmark
        }
    }
    
    var path : String? {
        return url?.path
    }
    
    var icon: NSImage? {
        guard let gamePath = path else { return nil }
        return NSWorkspace.shared.icon(forFile: gamePath)
    }
    
    var isRunning : Bool {
        return runningApp != nil
    }
    
    var runningApp : NSRunningApplication? {
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            guard let appURL = app.bundleURL ?? app.executableURL else { continue }
            if let gameURL = self.url, URL.init(fileURLWithPath: (gameURL as URL).absoluteString) == URL.init(fileURLWithPath: appURL.absoluteString) { return app }
        }
        return nil
    }
    
    var pid : pid_t? {
        return runningApp?.processIdentifier
    }
    
    init?(url fullURL:NSURL) {
        guard let name = ((fullURL.path as NSString?)?.lastPathComponent as NSString?)?.deletingPathExtension else {
            return nil
        }
        self.name = name

        guard let urlBookmark = try? fullURL.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil) else {
            return nil
        }
        self.urlBookmark = urlBookmark
        
        super.init()
    }
    
    func saveToFile(directory: String) {
        NSKeyedArchiver.archiveRootObject(self, toFile: "\(directory)/\(name)")
    }
    
    func deleteFiles(gameDirectory: String, sessionDirectory: String) {
        for session in sessions {
            session.deleteFile(directory: sessionDirectory)
        }
        do {
            try FileManager.default.removeItem(atPath: "\(gameDirectory)/\(name)")
        }
        catch _ {}
    }
    
    //NSCoding Protocol
    required init?(coder decoder: NSCoder) {
        if let savedBookmark = decoder.decodeObject(forKey: "MLGameURLBookmark") as? Data {
            urlBookmark = savedBookmark
        } else if let savedURL = decoder.decodeObject(forKey: "MLGameURL") as? NSURL {
            guard let bookmarkData = try? savedURL.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil) else {
                return nil
            }
            urlBookmark = bookmarkData
        } else {
            return nil
        }
        
        name = decoder.decodeObject(forKey: "MLGameName") as! String
        sessions = decoder.decodeObject(forKey: "MLGameSessions") as! [Session]
        displayName = decoder.decodeObject(forKey: "MLGameDisplayName") as? String
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(urlBookmark, forKey: "MLGameURLBookmark")
        coder.encode(name, forKey: "MLGameName")
        coder.encode(sessions, forKey: "MLGameSessions")
        coder.encode(displayName, forKey: "MLGameDisplayName")
    }
}
