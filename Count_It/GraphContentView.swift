//
//  GraphView.swift
//  Count_It
//
//  Created by Michael LaRandeau on 8/12/15.
//  Copyright (c) 2015 Michael LaRandeau. All rights reserved.
//

import Cocoa

class GraphContentView: NSView {
    
    weak var app = NSApplication.shared.delegate as? AppDelegate
    @IBOutlet weak var parent: GraphView!
    
    let innerContentPadding: CGFloat = 20
    let yScaleBuffer: Double = 5
    var yScaleMax: CGFloat = 0
    var yScaleMin: CGFloat = 0
    let baseScaleSize = NSSize(width: 640, height: 360)
    var drawRegion: NSRect?
    var containerSize: NSSize!
    let pointHighlight = GraphPointHighlight()
    let tickMarkLabelAttributes: [NSAttributedStringKey:AnyObject] = [NSAttributedStringKey.font:NSFont.systemFont(ofSize: 10),
        NSAttributedStringKey.foregroundColor:NSColor.black]
    
    var xScrollProportion: CGFloat?
    var yScrollProportion: CGFloat?
    var xScrollOffset: CGFloat?
    var yScrollOffset: CGFloat?
    
    var currentSessionAverage: Double?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        pointHighlight.isHidden = true
        addSubview(pointHighlight)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let context = NSGraphicsContext.current {
            //Set Background
            /*NSColor(calibratedRed: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1.0).set()
            NSRectFill(bounds)*/
            
            if parent.session != nil && parent.session!.samples.count > 0 {
                setYScaleConstants()
                
                //Draw Background and Shadow
                var blurRadius: CGFloat = 10
                if drawRegion!.width == frame.width && drawRegion!.height == frame.height {
                    blurRadius = 0
                }
                NSColor.white.setFill()
                let shadow = NSShadow()
                shadow.shadowOffset = NSMakeSize(0, 0)
                shadow.shadowBlurRadius = blurRadius
                shadow.shadowColor = NSColor.black.withAlphaComponent(0.75)
                shadow.set()
                let graphBackground = NSBezierPath()
                graphBackground.appendRoundedRect(drawRegion!, xRadius: blurRadius * 0.5, yRadius: blurRadius * 0.5)
                graphBackground.fill()
                shadow.shadowColor = nil
                shadow.set()
                
                //Position
                let reposition = NSAffineTransform()
                reposition.translateX(by: drawRegion!.origin.x, yBy: drawRegion!.origin.y)
                reposition.concat()
                
                //Draw the graph
                let contentRegion = drawAxis(context: context)
                drawTickMarks(context: context, graphContent: contentRegion)
                if !parent.holdDraw && !(parent.session!.samples.count > 1000 && inLiveResize) {
                    removeAllTrackingAreas()
                    drawCurve(context: context, graphContent: contentRegion)
                }
            }
            else {
                currentSessionAverage = nil
                removeAllTrackingAreas()
                removeHighlight()
                var message = ""
                if parent.session == nil { message = "No Recording Selected" }
                else if parent.session!.samples.count == 0 { message = "Data Points Not Found" }
                drawEmptyMessage(context: context, label: message)
            }
        }
    }
    
    override func viewWillDraw() {
        parent.popover.performClose(nil)
        
        let containerWidth = parent.frame.size.width
        let containerHeight = parent.frame.size.height - parent.header.frame.size.height
        containerSize = NSSize(width: containerWidth, height: containerHeight)
        
        if parent.session == nil {
            drawRegion = NSRect(x: 0, y: 0, width: containerSize.width, height: containerSize.height)
            setFrameSize(containerSize)
        }
        else {
        
            let xPadding: CGFloat = 15
            let yPadding: CGFloat = 15
            var drawOriginX: CGFloat?
            var drawOriginY: CGFloat?
            //Set Region Size
            var drawRegionSize: NSSize
            let zoomLevel = app!.mainWindow.toolbar.zoom.selectedTag()
            if zoomLevel == 3 {
                //Fit Height
                drawOriginY = yPadding
                let height = containerSize.height - yPadding * 2
                let width = height / 9 * 16
                drawRegionSize = NSSize(width: width, height: height)
            }
            else if zoomLevel == 2 {
                //Fit Width
                drawOriginX = xPadding
                let width = containerSize.width - xPadding * 2
                let height = width / 16 * 9
                drawRegionSize = NSSize(width: width, height: height)
            }
            else if zoomLevel == 1 {
                //Fit to View
                drawOriginX = xPadding
                drawOriginY = yPadding
                drawRegionSize = NSSize(width: containerSize.width - xPadding * 2, height: containerSize.height - yPadding * 2)
                //drawRegionSize = containerSize
            }
            else {
                //Fit by Slider Scale
                let sliderZoomLevel = Double(app!.mainWindow.toolbar.zoomLevel) / 100
                drawRegionSize = NSSize(width: baseScaleSize.width * CGFloat(sliderZoomLevel), height: baseScaleSize.height * CGFloat(sliderZoomLevel))
            }
            
            //Size View
            let frameWidth = containerSize.width < drawRegion!.size.width + xPadding * 2 ? drawRegion!.size.width + xPadding * 2 : containerSize.width
            let frameHeight = containerSize.height < drawRegion!.size.height + yPadding * 2 ? drawRegion!.size.height + yPadding * 2 : containerSize.height
            //frameWidth += xPadding * 2
            //frameHeight += yPadding * 2
            if frame.size.width != frameWidth || frame.size.height != frameHeight {
                setFrameSize(NSSize(width: frameWidth, height: frameHeight))
                needsDisplay = true
            }
            
            //Set Region Origin
            if drawOriginX == nil { drawOriginX = bounds.midX - drawRegionSize.width * 0.5 }
            if drawOriginY == nil { drawOriginY = bounds.midY - drawRegionSize.height * 0.5 }
            if drawOriginX! < xPadding { drawOriginX = xPadding }
            if drawOriginY! < yPadding { drawOriginY = yPadding }
            if inLiveResize {
                if xScrollOffset != nil {
                    drawOriginX! = -xScrollOffset! + xPadding
                    if drawOriginX! + drawRegion!.size.width + xPadding < containerSize.width {
                        drawOriginX = containerSize.width - drawRegion!.size.width - xPadding
                        let offset = drawOriginX! * 0.5
                        if offset > xPadding {
                            drawOriginX! -= offset
                            xScrollOffset = nil
                            xScrollProportion = 0
                        }
                    }
                }
                if yScrollOffset != nil {
                    drawOriginY! = -yScrollOffset! + yPadding
                    if drawOriginY! + drawRegion!.size.height + yPadding < containerSize.height {
                        drawOriginY = containerSize.height - drawRegion!.size.height - yPadding
                        let offset = drawOriginY! * 0.5
                        if offset > yPadding {
                            drawOriginY! -= offset
                            yScrollOffset = nil
                            yScrollProportion = 0
                        }
                    }
                }
            }
            let drawRegionPoint = NSPoint(x: drawOriginX!, y: drawOriginY!)
            drawRegion = NSRect(origin: drawRegionPoint, size: drawRegionSize)
        }
        super.viewWillDraw()
    }
    
    override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        
        setInitialScrollingInfo()
    }
    
    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        setScrollPosition()
        needsDisplay = true
    }
    
    func setInitialScrollingInfo() {
        xScrollOffset = visibleRect.origin.x
        yScrollOffset = visibleRect.origin.y
        
        xScrollProportion = xScrollOffset! / bounds.width
        yScrollProportion = yScrollOffset! / bounds.height
    }
    
    func setScrollPosition() {
        if !inLiveResize && xScrollProportion != nil && yScrollProportion != nil {
            scroll(NSPoint(x: bounds.width * xScrollProportion!, y: bounds.height * yScrollProportion!))
            if !inLiveResize {
                xScrollProportion = nil
                yScrollProportion = nil
                xScrollOffset = nil
                yScrollOffset = nil
            }
        }
    }
    
    func setYScaleConstants() {
        if parent.session != nil {
            yScaleMax = CGFloat(parent.session!.sampleMax)
            yScaleMin = CGFloat(parent.session!.sampleMin!)
            //yScaleMax = CGFloat(parent.session!.sampleMax + (yScaleBuffer - (parent.session!.sampleMax % yScaleBuffer)))
            //yScaleMin = CGFloat(parent.session!.sampleMin! - (parent.session!.sampleMin! % yScaleBuffer))
        }
        else {
            yScaleMax = 0
            yScaleMin = 0
        }
    }
    
    func drawEmptyMessage(context: NSGraphicsContext, label: String) {
        //Draw Message that no recording is selected
        let font = NSFont.systemFont(ofSize: 35)
        let fontColor = NSColor(red: 150 / 255, green: 150 / 255, blue: 150 / 255, alpha: 1)
        let attributes: [NSAttributedStringKey:AnyObject] = [NSAttributedStringKey.font:font,NSAttributedStringKey.foregroundColor:fontColor]
        let message: NSString = label as NSString
        let xPos = drawRegion!.midX - message.size(withAttributes: attributes).width * 0.5
        let yPos = drawRegion!.midY + parent.header.frame.size.height - message.size(withAttributes: attributes).height * 0.5
        message.draw(at: NSPoint(x: xPos, y: yPos), withAttributes: attributes)
    }
    
    func drawAxis(context: NSGraphicsContext)->NSRect {
        let axisOriginYOffset: CGFloat = 75
        let axisOriginXOffset: CGFloat = axisOriginYOffset + CGFloat(parent.numFormatter.maximumFractionDigits * 5) + 25
        let topOffset: CGFloat = 25
        let axisEndOffset: CGFloat = 25
        let axisTail: CGFloat = 25
        let axisWidth = drawRegion!.width - axisOriginXOffset - axisEndOffset
        let axisHeight = drawRegion!.height - axisOriginYOffset - topOffset
        
        NSColor.black.set()
        let axis = NSBezierPath()
        axis.lineWidth = 2
        //X-Axis
        axis.move(to: NSPoint(x: axisOriginXOffset - axisTail, y: axisOriginYOffset))
        axis.line(to: NSPoint(x: drawRegion!.width - axisEndOffset, y: axisOriginYOffset))
        //Y-Axis
        axis.move(to: NSPoint(x: axisOriginXOffset, y: axisOriginYOffset - axisTail))
        axis.line(to: NSPoint(x: axisOriginXOffset, y: drawRegion!.height - topOffset))
        axis.stroke()
        
        //X-Axis Label
        let zeroLabel: NSString = "00:00"
        let zeroLabelSize = zeroLabel.size(withAttributes: tickMarkLabelAttributes)
        zeroLabel.draw(at: NSPoint(x: axisOriginXOffset - (zeroLabelSize.width * 0.5), y: axisOriginYOffset - axisTail - zeroLabelSize.height - 5), withAttributes: tickMarkLabelAttributes)
        
        let labelFont = NSFont.systemFont(ofSize: 12)
        let labelColor = NSColor.black
        let timeLabelAttributes: [NSAttributedStringKey:AnyObject] = [NSAttributedStringKey.font:labelFont,
            NSAttributedStringKey.foregroundColor:labelColor]
        let timeLabel = NSString(string: "Time (mm:ss)")
        let timeSize = timeLabel.size(withAttributes: timeLabelAttributes)
        let timeXPos = axisOriginXOffset + (axisWidth * 0.5) - (timeSize.width * 0.5)
        let timeYPos = (axisOriginYOffset * 0.25) - (timeSize.height * 0.5)
        timeLabel.draw(at: NSPoint(x: timeXPos, y: timeYPos), withAttributes: timeLabelAttributes)
        
        //Y-Axis Label
        let fpsLabelAttributes: [NSAttributedStringKey:AnyObject] = [NSAttributedStringKey.font:labelFont,
            NSAttributedStringKey.foregroundColor:labelColor]
        let fpsLabel = NSString(string: "Frames Per Second")
        let fpsSize = fpsLabel.size(withAttributes: fpsLabelAttributes)
        let fpsXPos = axisOriginYOffset + (axisHeight * 0.5) - (fpsSize.width * 0.5)
        //let fpsXPos = bounds.midY - fpsSize.width * 0.5
        let fpsYPos = drawRegion!.width - (axisOriginYOffset * 0.25) - (fpsSize.height * 0.5)
        
        let transform = NSAffineTransform()
        transform.translateX(by: drawRegion!.width, yBy: 0)
        transform.rotate(byDegrees: 90)
        transform.concat()
        
        fpsLabel.draw(at: NSPoint(x: fpsXPos, y: fpsYPos), withAttributes: fpsLabelAttributes)
        
        transform.invert()
        transform.concat()
        
        return NSMakeRect(axisOriginXOffset, axisOriginYOffset, axisWidth, axisHeight)
    }
    
    func drawCurve(context: NSGraphicsContext, graphContent content: NSRect) {
        let xScale = (content.size.width - innerContentPadding) / CGFloat(parent.session!.interval!)
        let yScale = (content.size.height - innerContentPadding * 2) / (yScaleMax - yScaleMin)
        let curve = NSBezierPath()
        curve.lineWidth = 2
        curve.lineJoinStyle = NSBezierPath.LineJoinStyle.roundLineJoinStyle
        let points = NSBezierPath()
        let pointSize = NSSize(width: 10, height: 10)
        
        let sessionStart = parent.session!.start!
        var prevPoint = NSPoint(x: -100, y: -100)
        let maxX = content.origin.x + content.size.width - innerContentPadding
        let maxY = content.origin.y + content.size.height - innerContentPadding
        var first = true
        
        //Stat Info
        var frameRateSum: Double = 0
        var frameRateCount: Double = 0
        var maxPoint: NSPoint?
        var minPoint: NSPoint?
        
        for sample in parent.session!.samples {
            var xPos = content.origin.x + CGFloat(sample.time.timeIntervalSince(sessionStart as Date)) * xScale
            if xPos > maxX  { xPos = maxX }
            
            var yPos = (CGFloat(sample.frameRate - Double(yScaleMin)) * yScale) + content.origin.y + innerContentPadding
            if yPos > maxY { yPos = maxY }
            
            if abs(prevPoint.x - xPos) >= pointSize.width || abs(prevPoint.y - yPos) >= pointSize.height {
                let newPoint = NSPoint(x: xPos, y: yPos)
                let newPointRect = NSMakeRect(xPos - pointSize.width * 0.5, yPos - pointSize.height * 0.5, pointSize.width, pointSize.height)
                points.appendOval(in: newPointRect)
                
                if first {
                    curve.move(to: newPoint)
                    first = false
                }
                else { curve.line(to: newPoint) }
                
                prevPoint = newPoint
                
                if maxPoint == nil || newPoint.y > maxPoint!.y { maxPoint = newPoint }
                if minPoint == nil || newPoint.y < minPoint!.y { minPoint = newPoint }
                
                let trackingRect = NSMakeRect(newPointRect.origin.x + drawRegion!.origin.x, newPointRect.origin.y + drawRegion!.origin.y, newPointRect.width, newPointRect.height)
                let tracking = NSTrackingArea(rect: trackingRect, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: ["Sample":sample])
                addTrackingArea(tracking)
                
                frameRateSum += sample.frameRate
                frameRateCount += 1
            }
        }
        curve.stroke()
        points.fill()
        
        //Stats
        let stats = NSBezierPath()
        stats.lineWidth = 2
        
        //Min/Max
        let minMaxLabelPadding: CGFloat = 5
        
        let labelTickLength: CGFloat = 20
        let labelTickLeft: CGFloat = content.origin.x - (labelTickLength * 0.5)
        if minPoint != nil {
            if let sampleMin = parent.session!.sampleMin {
                let minLabel: NSString = (parent.numFormatter.string(from: NSNumber(value: sampleMin))! as String + " (min)") as NSString
                let minLabelSize = minLabel.size(withAttributes: tickMarkLabelAttributes)
                minLabel.draw(at: NSPoint(x: content.origin.x - minMaxLabelPadding - minLabelSize.width - (labelTickLength * 0.5), y: minPoint!.y - minLabelSize.height * 0.5), withAttributes: tickMarkLabelAttributes)
                NSBezierPath.strokeLine(from: NSPoint(x: labelTickLeft, y: minPoint!.y), to: NSPoint(x: labelTickLeft + labelTickLength, y: minPoint!.y))
            }
        }
        if maxPoint != nil {
            let maxLabel: NSString = (parent.numFormatter.string(from: NSNumber(value: parent.session!.sampleMax))! as String + " (max)") as NSString
            let maxLabelSize = maxLabel.size(withAttributes: tickMarkLabelAttributes)
            maxLabel.draw(at: NSPoint(x: content.origin.x - minMaxLabelPadding - maxLabelSize.width - (labelTickLength * 0.5), y: maxPoint!.y - maxLabelSize.height * 0.5), withAttributes: tickMarkLabelAttributes)
            NSBezierPath.strokeLine(from: NSPoint(x: labelTickLeft, y: maxPoint!.y), to: NSPoint(x: labelTickLeft + labelTickLength, y: maxPoint!.y))
        }
        
        let minMax = NSBezierPath()
        NSColor(calibratedRed: 242 / 255, green: 31 / 255, blue: 31 / 255, alpha: 1.0).setFill()
        if minPoint != nil {
            minMax.appendOval(in: NSMakeRect(minPoint!.x - pointSize.width * 0.5 - 1, minPoint!.y - pointSize.height * 0.5 - 1, pointSize.width + 2, pointSize.height + 2))
        }
        if maxPoint != nil {
            minMax.appendOval(in: NSMakeRect(maxPoint!.x - pointSize.width * 0.5 - 1, maxPoint!.y - pointSize.height * 0.5 - 1, pointSize.width + 2, pointSize.height + 2))
        }
        minMax.fill()
        
        //Average
        NSColor(calibratedRed: 12 / 255, green: 240 / 255, blue: 73 / 255, alpha: 1.0).setStroke()
        let averageFrameRate = CGFloat(frameRateSum/frameRateCount)
        currentSessionAverage = Double(averageFrameRate)
        let averageYPos = ((CGFloat(frameRateSum / frameRateCount) - yScaleMin) * yScale) + content.origin.y + innerContentPadding
        //let averageXStartPos = content.origin.x - 5
        let averageXEndPos = content.origin.x + content.size.width
        stats.move(to: NSPoint(x: labelTickLeft, y: averageYPos))
        stats.line(to: NSPoint(x: averageXEndPos, y: averageYPos))
        stats.stroke()
        stats.fill()
        
        let averageLabel = NSString(string: parent.numFormatter.string(from: NSNumber(value: Double(averageFrameRate)))! + " (avg)")
        let averageLabelSize = averageLabel.size(withAttributes: tickMarkLabelAttributes)
        averageLabel.draw(at: NSPoint(x: labelTickLeft - averageLabelSize.width - minMaxLabelPadding, y: averageYPos - (averageLabelSize.height * 0.5)), withAttributes: tickMarkLabelAttributes)
        
        /*let averageTrackingRectPadding: CGFloat = 3
        let averageTrackingRect = NSMakeRect(drawRegion!.origin.x + averageXStartPos, drawRegion!.origin.y + averageYPos - averageTrackingRectPadding, averageXEndPos - averageXStartPos, averageTrackingRectPadding * 2)
        let averageTrackingArea = NSTrackingArea(rect: averageTrackingRect, options: [NSTrackingAreaOptions.MouseEnteredAndExited, NSTrackingAreaOptions.ActiveAlways], owner: self, userInfo: ["Sample":Sample(frameRate: Double(averageFrameRate), count: 1)])
        addTrackingArea(averageTrackingArea)*/
    }
    
    func drawTickMarks(context: NSGraphicsContext, graphContent content: NSRect) {
        let tickLength: CGFloat = 20
        let tickLabelPadding: CGFloat = 5
        //let tickLabelYRightX: CGFloat = content.origin.x - (tickLength * 0.5) - tickLabelPadding
        let tickLabelXTopY: CGFloat = content.origin.y - (tickLength * 0.5) - tickLabelPadding
        
        let tickMarks = NSBezierPath()
        //let yAxisTicksXStart: CGFloat = content.origin.x - tickLength * 0.5
        //let yAxisTicksXEnd: CGFloat = content.origin.x + tickLength * 0.5
        let xAxisTicksYStart: CGFloat = content.origin.y - tickLength * 0.5
        let xAxisTicksYEnd: CGFloat = content.origin.y + tickLength * 0.5
        ///////////////////////////////////////
        //Y Tick Marks and Labels
        ///////////////////////////////////////
        //Minimum
        /*var yAxisY: CGFloat = content.origin.y + innerContentPadding
        tickMarks.moveToPoint(NSPoint(x: yAxisTicksXStart, y: yAxisY))
        tickMarks.lineToPoint(NSPoint(x: yAxisTicksXEnd, y: yAxisY))
        let minYLabel = NSString(string: parent.numFormatter.stringFromNumber(NSNumber(double: Double(yScaleMin)))!)
        let minYSize = minYLabel.sizeWithAttributes(tickMarkLabelAttributes)
        let minYxPos = tickLabelYRightX - minYSize.width
        let minYyPos = yAxisY - (minYSize.height * 0.5)
        minYLabel.drawAtPoint(NSPoint(x: minYxPos, y: minYyPos), withAttributes: tickMarkLabelAttributes)
        //Middle
        yAxisY = content.origin.y + (content.size.height * 0.5)
        tickMarks.moveToPoint(NSPoint(x: yAxisTicksXStart, y: yAxisY))
        tickMarks.lineToPoint(NSPoint(x: yAxisTicksXEnd, y: yAxisY))
        let midYLabel = NSString(string: parent.numFormatter.stringFromNumber(NSNumber(double: Double((yScaleMax + yScaleMin) / 2)))!)
        let midYSize = midYLabel.sizeWithAttributes(tickMarkLabelAttributes)
        let midYxPos = tickLabelYRightX - midYSize.width
        let midYyPos = yAxisY - midYSize.height * 0.5
        midYLabel.drawAtPoint(NSPoint(x: midYxPos, y: midYyPos), withAttributes: tickMarkLabelAttributes)
        //Maximum
        yAxisY = content.origin.y + content.size.height - innerContentPadding
        tickMarks.moveToPoint(NSPoint(x: yAxisTicksXStart, y: yAxisY))
        tickMarks.lineToPoint(NSPoint(x: yAxisTicksXEnd, y: yAxisY))
        let maxYLabel = NSString(string: parent.numFormatter.stringFromNumber(NSNumber(double: Double(yScaleMax)))!)
        let maxYSize = maxYLabel.sizeWithAttributes(tickMarkLabelAttributes)
        let maxYxPos = tickLabelYRightX - maxYSize.width
        let maxYyPos = yAxisY - (maxYSize.height * 0.5)
        maxYLabel.drawAtPoint(NSPoint(x: maxYxPos, y: maxYyPos), withAttributes: tickMarkLabelAttributes)*/
        
        ///////////////////////////////////////
        //X Tick Marks and Labels
        ///////////////////////////////////////
        //Middle
        var xAxisX: CGFloat = content.origin.x + (content.size.width * 0.5)
        tickMarks.move(to: NSPoint(x: xAxisX, y: xAxisTicksYStart))
        tickMarks.line(to: NSPoint(x: xAxisX, y: xAxisTicksYEnd))
        let midXLabel: NSString = "\(parent.session!.formatInterval(interval: parent.session!.interval! * 0.5)!)" as NSString
        let midXSize = midXLabel.size(withAttributes: tickMarkLabelAttributes)
        let midXxPos = xAxisX - midXSize.width * 0.5
        let midXyPos = tickLabelXTopY - midXSize.height
        midXLabel.draw(at: NSPoint(x: midXxPos, y: midXyPos), withAttributes: tickMarkLabelAttributes)
        //Maximum
        xAxisX = content.origin.x + content.size.width - innerContentPadding
        tickMarks.move(to: NSPoint(x: xAxisX, y: xAxisTicksYStart))
        tickMarks.line(to: NSPoint(x: xAxisX, y: xAxisTicksYEnd))
        let maxXLabel = NSString(string: "\(parent.session!.formatInterval(interval: nil)!)")
        let maxXSize = maxXLabel.size(withAttributes: tickMarkLabelAttributes)
        let maxXxPos = xAxisX - maxXSize.width * 0.5
        let maxXyPos = tickLabelXTopY - maxXSize.height
        maxXLabel.draw(at: NSPoint(x: maxXxPos, y: maxXyPos), withAttributes: tickMarkLabelAttributes)
        
        tickMarks.stroke()
    }
    
    func removeAllTrackingAreas() {
        while trackingAreas.count > 0 {
            removeTrackingArea(trackingAreas[0] )
        }
    }
    
    func removeHighlight() {
        pointHighlight.isHidden = true
    }
    
    func positionHighlight(rect: NSRect) {
        //pointHighlight.hidden = false
        let padding: CGFloat = 4
        let highlightSize = NSSize(width: rect.size.width + (padding * 2), height: rect.size.height + (padding * 2))
        pointHighlight.setFrameOrigin(NSPoint(x: rect.origin.x - padding, y: rect.origin.y - padding))
        pointHighlight.setFrameSize(highlightSize)
        
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        if let info = theEvent.trackingArea?.userInfo as? [String:Sample] {
            if let details = parent.popover.contentViewController?.view as? GraphSampleDetails {
                details.sample = info["Sample"]
                details.needsDisplay = true
                parent.popover.animates = false
                parent.popover.show(relativeTo: theEvent.trackingArea!.rect, of: self, preferredEdge: NSRectEdge.maxY)
                positionHighlight(rect: theEvent.trackingArea!.rect)
            }
        }
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        let info = theEvent.trackingArea?.userInfo as? [String:Sample]
        if info != nil {
            parent.popover.animates = true
            parent.popover.performClose(nil)
            if let details = parent.popover.contentViewController?.view as? GraphSampleDetails {
                details.sample = nil
            }
        }
        removeHighlight()
    }
}






