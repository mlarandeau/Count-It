//
//  AddNewListController.swift
//  Count_It
//
//  Created by Michael LaRandeau on 5/17/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class AddNewListController: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    var appCollection = GameCollection()
    var withoutHiddenCollection = GameCollection()
    @IBOutlet weak var view: NSTableView!
    @IBOutlet var add: NSButton!
    @IBOutlet var showHidden: NSButton!
    
    var serviceType: String = ""
    
    var selectedGames: [Game]? {
        get {
            if view.selectedRowIndexes.count > 0 {
                var selected: [Game] = []
                let set: NSIndexSet = view.selectedRowIndexes as NSIndexSet
                set.enumerate({ [unowned self] (i,boolRef) in
                    let cell = self.view.view(atColumn: 0, row: i, makeIfNecessary: true) as? NSTableCellView
                    if cell != nil {
                        if self.showHidden.state == .on { selected += [self.appCollection[i]] }
                        else { selected += [self.withoutHiddenCollection[i]] }
                    }
                })
                if selected.count > 0 { return selected }
            }
            return nil
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "runningApplications" {
            if app!.mainWindow.activeSheetType == "Running" {
                updateAppCollection()
                //view.reloadData()
            }
        }
    }
    
    @IBAction func toggleHidden(sender: NSButton) {
        view.reloadData()
    }
    
    func updateAppCollection() {
        appCollection = GameCollection()
        serviceType = ((app!.mainWindow.activeSheetType! as NSString).lastPathComponent as NSString).deletingPathExtension
        if serviceType == "" { serviceType = app!.mainWindow.activeSheetType! }
        if serviceType == "Running" {
            let running = NSWorkspace.shared.runningApplications
            let allowedDirectories: NSArray = ["Applications","Users"]
            for app in running {
                if app != NSRunningApplication.current {
                    var appURL = app.bundleURL
                    if appURL == nil { appURL = app.executableURL }
                    if appURL != nil && appURL!.pathComponents.count >= 2 && allowedDirectories.index(of: appURL!.pathComponents[1]) != NSNotFound {
                        checkAndAddToCollection(rawURL: appURL! as NSURL)
                    }
                }
                
                /*if app != NSRunningApplication.currentApplication() && app.bundleURL != nil && app.bundleURL!.pathComponents != nil && app.bundleURL!.pathComponents!.count >= 2 && allowedDirectories.indexOfObject(app.bundleURL!.pathComponents![1]) != NSNotFound {
                    checkAndAddToCollection(app.bundleURL!)
                }*/
            }
        }
        else if serviceType == "Steam" {
            let steamRoot = NSHomeDirectory() + "/Library/Application Support/Steam"
            var gameFolders = [steamRoot + "/SteamApps/common"]
            let steamLibraryFolders = NSURL(fileURLWithPath: steamRoot + "/SteamApps/libraryfolders.vdf")
            let vdf = VDFParser.decode(url: steamLibraryFolders)
            if vdf.count > 0 {
                let folders = vdf["LibraryFolders"] as! NSMutableDictionary
                for key in folders.allKeys as! [String] {
                    if Int(key) != nil {
                        gameFolders += [(folders[key] as! String)]
                    }
                }
            }
            for path in gameFolders {
                findAppsRecursively(rootPath: path)
            }
        }
        else if serviceType == "Mac Game Store" {
            var rootPath = "/Applications/MacGameStore"
            if let serviceBundle = Bundle(path: app!.mainWindow.activeSheetType!) {
                if let bundleId = serviceBundle.bundleIdentifier {
                    let defaults = UserDefaults.standard
                    defaults.addSuite(named: bundleId)
                    if let mgsPath = defaults.string(forKey: "MGSInstallDirectory") {
                        rootPath = mgsPath
                    }
                }
            }
            findAppsRecursively(rootPath: rootPath)
        }
        else if serviceType == "GalaxyClient" {
            var gogFolders: [String] = []
            let sql = SQLiteController()
            let gogGames = sql.getAllGames() as! [String]
            for path in gogGames {
                gogFolders += [path]
            }
            for path in gogFolders {
                checkAndAddToCollection(rawURL: NSURL(fileURLWithPath: path, isDirectory: false))
            }
        }
        else if serviceType == "Battle.net" {
            var battleNetGamePaths: [String] = []
            if let battleData = NSData(contentsOfFile: "/Users/Shared/Battle.net/Agent/agent.db") {
                if let battleJSON = (try? JSONSerialization.jsonObject(with: battleData as Data, options: [])) as? NSDictionary {
                    let gamePath = ["/game","resource","gameroot"]
                    if let battleGame = battleNetNode(jsonObj: battleJSON, nodePath: gamePath) as? [String] {
                        var gameName: [String] = []
                        for game in battleGame {
                            if game != "battle.net" {
                                gameName += [game]
                            }
                        }
                        for game in gameName {
                            if let gameInstallDir = battleNetNode(jsonObj: battleJSON, nodePath: ["/game/" + game,"resource","game","install_dir"]) as? String {
                                if let gameRegexPath = battleNetNode(jsonObj: battleJSON,nodePath:["/game/"+game,"resource","game","binaries","game","regex"]) as? String {
                                    if let regExp = try? NSRegularExpression(pattern: gameRegexPath, options: NSRegularExpression.Options.caseInsensitive) {
                                        let baseURL = NSURL(fileURLWithPath: gameInstallDir, isDirectory: true)
                                        let manager = FileManager()
                                        if let enumerator = manager.enumerator(at: baseURL as URL, includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
                                            var enumObj: AnyObject? = enumerator.nextObject() as AnyObject?
                                            while enumObj != nil {
                                                if let url = enumObj as? NSURL {
                                                    if regExp.numberOfMatches(in: url.path!, options: [], range: NSMakeRange(0, (url.path!).count)) > 0 {
                                                        let gameURL = NSURL(fileURLWithPath: url.path!, isDirectory: false)
                                                        if gameURL.pathExtension == "app" {
                                                            battleNetGamePaths += [gameURL.path!]
                                                        }
                                                    }
                                                    enumObj = enumerator.nextObject() as AnyObject?
                                                }
                                            }
                                        }
                                    }
                                }
                                else if let gameRelativePath = battleNetNode(jsonObj: battleJSON, nodePath: ["/game/"+game,"resource","game","binary_launch_path"]) as? String {
                                    battleNetGamePaths += ["\(gameInstallDir)/\(gameRelativePath)"]
                                }
                            }
                        }
                    }
                }
            }
            for path in battleNetGamePaths {
                checkAndAddToCollection(rawURL: NSURL(fileURLWithPath: path, isDirectory: false))
            }
        }
        if serviceType != "Running" {
            for game in appCollection.orderedCollection {
                if let gamePath = game.path {
                    findAppsRecursively(rootPath: gamePath)
                }
            }
        }
    }
    
    func battleNetNode(jsonObj:NSDictionary, nodePath: [String])->AnyObject? {
        var activeNode = jsonObj
        for i in 0..<nodePath.count {
            if i == nodePath.count - 1 {
                return activeNode.object(forKey: nodePath[i]) as AnyObject?
            }
            else {
                if let nextNode = activeNode[nodePath[i]] as? NSDictionary {
                    activeNode = nextNode
                }
                else { return nil }
            }
        }
        return nil
    }
    
    func findAppsRecursively(rootPath: String) {
        let manager = FileManager()
        let baseURL = NSURL(fileURLWithPath: rootPath, isDirectory: true)
        //if baseURL != nil {
            let enumerator = manager.enumerator(at: baseURL as URL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsPackageDescendants, errorHandler: nil)
            if enumerator != nil {
                var enumObj: AnyObject? = enumerator!.nextObject() as AnyObject?
                while enumObj != nil {
                    if let url = enumObj as? NSURL {
                        checkAndAddToCollection(rawURL: url)
                    }
                    enumObj = enumerator!.nextObject() as AnyObject?
                }
            }
        //}
    }
    
    func checkAndAddToCollection(rawURL:NSURL) {
        if rawURL.pathExtension != nil {
            let url = NSURL(fileURLWithPath: rawURL.path!, isDirectory: false)
            var isAllowed = false
            if url.pathExtension == "app" { isAllowed = true }
            else if serviceType == "Running" {
                var typeIdentifier: AnyObject? = nil
                do {
                    try url.getResourceValue(&typeIdentifier, forKey: URLResourceKey.typeIdentifierKey)
                    
                    if let utiString = typeIdentifier as? String {
                        if utiString == "public.unix-executable" {
                            isAllowed = true
                        }
                    }
                }
                catch {
                    isAllowed = false
                }
            }
            
            if isAllowed {
                guard let newGame = Game(url:url) else { return }
                let fromAppCollection = appCollection[newGame.name]
                let fromWithoutHiddenCollection = withoutHiddenCollection[newGame.name]
                if (fromAppCollection != nil || fromWithoutHiddenCollection != nil) {
                    if fromAppCollection != nil {
                        appCollection.remove(name: newGame.name)
                        appCollection.add(game: newGame)
                    }
                    if fromWithoutHiddenCollection != nil {
                        withoutHiddenCollection.remove(name: newGame.name)
                        withoutHiddenCollection.add(game: newGame)
                    }
                }
                else {
                    appCollection.add(game: newGame)
                    if app!.games[newGame.name] == nil && url.path?.range(of: "\\.app/",options: NSString.CompareOptions.regularExpression) == nil {
                        if withoutHiddenCollection[newGame.name] != nil { withoutHiddenCollection.remove(name: newGame.name) }
                        withoutHiddenCollection.add(game: newGame)
                    }
                }
            }
        }
    }

    override init() {
        super.init()
        
        NSWorkspace.shared.addObserver(self, forKeyPath: "runningApplications", options: [], context: nil)
    }
    
    //NSTableViewDelegate Methods
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var data: GameCollection
        if showHidden.state == .on { data = appCollection }
        else { data = withoutHiddenCollection }
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AppName"), owner: self) as? NSTableCellView
        if cell != nil {
            cell!.imageView?.image = data[row].icon
            cell!.textField!.stringValue = data[row].name
        }
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if view.selectedRowIndexes.count == 0 { add.isEnabled = false }
        else { add.isEnabled = true }
    }
    
    //NSTableViewDataSource Methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        if showHidden.state == .on { return appCollection.count }
        else { return withoutHiddenCollection.count }
    }
}
