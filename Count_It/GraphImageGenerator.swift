//
//  GraphImageGenerator.swift
//  Count_It
//
//  Created by Michael LaRandeau on 10/11/15.
//  Copyright © 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class GraphImageGenerator: NSView {
    
    var header: GraphHeaderView?
    var content: GraphContentView?
    var sysInfo: GraphSysInfoDetails?
    var fileType = NSBitmapImageRep.FileType.png

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor(calibratedRed: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0).set()
        bounds.fill()

        if header != nil && content != nil {
            let headerImage = getImageFrom(view: header!)
            let contentImage = getImageFrom(view: content!)
            let sysInfoImage = sysInfo != nil ? getImageFrom(view: sysInfo!) : nil
            
            if headerImage != nil && contentImage != nil {
                contentImage!.draw(at: NSPoint(x: 0, y: 0), from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
                let headerPos = NSPoint(x: 0, y: bounds.height - header!.bounds.height)
                headerImage!.draw(at: headerPos, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
                if sysInfoImage != nil {
                    sysInfoImage!.draw(at: NSPoint(x: headerPos.x + header!.bounds.width - sysInfoImage!.size.width, y: content!.bounds.height), from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
                }
            }
        }
    }
    
    func generateShareItems(game: Game, graph: GraphView)->[AnyObject] {
        var shareItems: [AnyObject] = []
        if let image = GraphImageGenerator().generateNSImage(header: graph.header, content: graph.content, imageType: NSBitmapImageRep.FileType.jpeg) {
            shareItems.append(image)
            let gameName = game.displayName != nil ? game.displayName : game.name
            let averageFPS = graph.content.currentSessionAverage
            let computer = graph.session?.systemInformation?.computerType != "" ? graph.session?.systemInformation?.computerType : graph.session?.systemInformation?.computerName
            if gameName != nil && (averageFPS != nil || computer != nil) {
                var message = "\"\(gameName!)\" running"
                if averageFPS != nil {
                    message += " at \(graph.numFormatter.string(from: NSNumber(value: averageFPS!))!) fps"
                }
                if computer != nil { message += " on my \(computer!)" }
                shareItems.append(message as AnyObject)
            }
        }
        return shareItems
    }
    
    func generateNSImage(header: GraphHeaderView, content: GraphContentView, imageType: NSBitmapImageRep.FileType?)->NSImage? {
        if let bitmap = generateImage(header: header, content: content, imageType: imageType) {
            if let bitmapCGImage = bitmap.cgImage {
                let image = NSImage(cgImage: bitmapCGImage, size: NSZeroSize)
                return image
            }
        }
        return nil
    }
    
    func generateImage(header: GraphHeaderView, content: GraphContentView, imageType: NSBitmapImageRep.FileType?)->NSBitmapImageRep? {
        if imageType != nil { fileType = imageType! }
        
        self.header = header
        self.content = content
        
        if let session = header.parent.session {
            if let info = session.systemInformation {
                self.sysInfo = GraphSysInfoDetails(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
                self.sysInfo!.systemInformation = info
                self.sysInfo!.shouldFillBackground = true
                self.sysInfo!.determineFrameSize()
                self.sysInfo!.display()
            }
        }
        else { self.sysInfo = nil }
        
        let finalWidth = content.bounds.width
        var finalHeight = header.bounds.height + content.bounds.height
        if self.sysInfo != nil { finalHeight += self.sysInfo!.bounds.height }
        
        setFrameSize(NSSize(width: finalWidth, height: finalHeight))
        
        display()
        
        if let bitmap = bitmapImageRepForCachingDisplay(in: bounds) {
            cacheDisplay(in: bounds, to: bitmap)
            return bitmap
        }
        
        return nil
    }
    
    func getImageFrom(view: NSView)->NSImage? {
        if let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
            view.cacheDisplay(in: view.bounds, to: bitmap)
            if let imageData = bitmap.representation(using: fileType, properties: [:]) {
                return NSImage(data: imageData)
            }
        }
        return nil
    }
}
