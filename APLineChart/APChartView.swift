//
//  APChartView.swift
//  linechart
//
//  Created by Attilio Patania on 20/03/15.
//  Copyright (c) 2015 zemirco. All rights reserved.
//

import UIKit
import QuartzCore

// delegate method
 protocol APChartViewDelegate {
    func didSelectDataPoint(selectedDots:[String:APChartPoint])
}


@IBDesignable class APChartView:UIView{
    var collectionLines:[APChartLine] = []
    var delegate: APChartViewDelegate!

    let labelAxesSize:CGSize = CGSize(width: 35.0, height: 20.0)
    var lineLayerStore: [CALayer] = []

    // default configuration

    /* MARK oook
    */
    @IBInspectable var axesVisible:Bool = true
    @IBInspectable var titleForX:String = "x"
    @IBInspectable var titleForY:String = "y"
    var marginBottom:CGFloat = 50.0
    lazy var marginLeft:CGFloat = {
        return self.labelAxesSize.width + self.labelAxesSize.height
        }()
    var marginTop:CGFloat = 25
    var marginRight:CGFloat = 25
    // #607d8b
    @IBInspectable var axesColor = UIColor(red: 96/255.0, green: 125/255.0, blue: 139/255.0, alpha: 1)
    // #f69988
    @IBInspectable var positiveAreaColor = UIColor(red: 246/255.0, green: 153/255.0, blue: 136/255.0, alpha: 1)
    // #72d572
    @IBInspectable var negativeAreaColor = UIColor(red: 114/255.0, green: 213/255.0, blue: 114/255.0, alpha: 1)

    
    @IBInspectable var gridVisible:Bool = false
    @IBInspectable var labelsXVisible:Bool = false
    @IBInspectable var labelsYVisible:Bool = false
    @IBInspectable var GridLinesX: CGFloat = 5.0
    @IBInspectable var GridLinesY: CGFloat = 5.0
    // #eeeeee
    @IBInspectable var gridColor = UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1)

    
    @IBInspectable var dotsVisible:Bool = false
    @IBInspectable var dotsBackgroundColor:UIColor = UIColor.whiteColor()
    @IBInspectable var areaUnderLinesVisible:Bool = true
    
    var animationEnabled = true
    @IBInspectable var showMean:Bool = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var showMeanProgressive:Bool = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    @IBInspectable var showMax:Bool = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var showMin:Bool = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    var animationDuration: CFTimeInterval = 1

//    @IBInspectable var areaBetweenLines = [-1, -1]
        
    
    let colors: [UIColor] = [
        UIColor.fromHex(0x1f77b4),
        UIColor.fromHex(0xff7f0e),
        UIColor.fromHex(0x2ca02c),
        UIColor.fromHex(0xd62728),
        UIColor.fromHex(0x9467bd),
        UIColor.fromHex(0x8c564b),
        UIColor.fromHex(0xe377c2),
        UIColor.fromHex(0x7f7f7f),
        UIColor.fromHex(0xbcbd22),
        UIColor.fromHex(0x17becf)
    ]

    
    var offsetX: Offset = Offset(min:0.0, max:1.0)
    var offsetY: Offset = Offset(min:0.0, max:1.0)
    
//    var basePoint:CGPoint = CGPoint(x: 0.0, y: 0.0)
    var pointZero:CGPoint {
        get {
            return drawingArea.origin
        }
    }
    var pointBase:CGPoint = CGPoint(x: 0.0, y: 0.0)
    var drawingArea:CGRect  = CGRectZero

    var selectetedXlayer:CAShapeLayer? = nil
    
    var removeAll: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        var line = APChartLine(chartView: self, title: "mio", lineWidth: 2.0, lineColor: self.colors[1])
        line.addPoint( CGPoint(x: 23.0, y: 159.0))
        line.addPoint( CGPoint(x: 34.0, y: 137.0))
        line.addPoint(CGPoint(x: 36.0, y: 160.0))
        line.addPoint(CGPoint(x: 49.0, y: 125.0))
        line.addPoint(CGPoint(x: 61.0, y: 140.0))
        line.addPoint(CGPoint(x: 72.0, y: 132.0))
        line.addPoint(CGPoint(x: 78.0, y: 138.0))
        line.addPoint(CGPoint(x: 95.0, y: 138.0))
        line.addPoint(CGPoint(x: 98.0, y: 175.0))
        line.addPoint(CGPoint(x: 101.0, y: 102.0))
        line.addPoint(CGPoint(x: 102.0, y: 92.0))
        line.addPoint(CGPoint(x: 115.0, y: 88.0))
        self.addLine(line)
        self.setNeedsDisplay()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addLine(line:APChartLine){

        collectionLines.append(line)
    }
    
    
    override func drawRect(rect: CGRect) {
        if removeAll {
            var context = UIGraphicsGetCurrentContext()
            CGContextClearRect(context, rect)
            return
        }
        

        // remove all labels
        for view: AnyObject in self.subviews {
            view.removeFromSuperview()
        }
        
        // remove all lines on device rotation
        for lineLayer in lineLayerStore {
            lineLayer.removeFromSuperlayer()
        }
        lineLayerStore.removeAll()
        
        updateDrawingArea()

        drawGrid()
        
        drawAxes()
        
        calculateOffsets()
        updateLinesDataStoreScaled()

        drawXLabels()
        drawYLabels()
        

        var layer:CAShapeLayer? = nil
        for  lineData in collectionLines {
            
            lineData.showMeanValue = showMean
            lineData.showMeanValueProgressive = showMeanProgressive
            lineData.showMaxValue = showMax

            if let layer = lineData.drawLine() {
                self.layer.addSublayer(layer)
                self.lineLayerStore.append(layer)
            }

            lineData.drawMeanValue()
            lineData.drawMeanProgressive()

            
            // draw dots
            if dotsVisible {
                if let dotsLayer = lineData.drawDots(dotsBackgroundColor) {
                    for ll in dotsLayer {
                        self.layer.addSublayer(ll)
                        self.lineLayerStore.append(ll)
                    }
                }
            }
            
            // draw area under line chart
            if areaUnderLinesVisible { lineData.drawAreaBeneathLineChart() }
            
        }

    }
   
    
    func updateDrawingArea(){
        drawingArea = CGRect(x: marginLeft, y: self.bounds.height-marginBottom, width: self.bounds.width  - marginLeft - marginRight, height: self.bounds.height - marginTop  - marginBottom)
        
        if !labelsXVisible {
            drawingArea.origin.y = self.bounds.height-self.labelAxesSize.height
            drawingArea.size.height = self.bounds.height - self.labelAxesSize.height - marginTop
        }
        if !labelsYVisible {
            drawingArea.origin.x = self.labelAxesSize.height
            drawingArea.size.width = self.bounds.width - self.labelAxesSize.height - marginRight
        }
        
    }
    
    /**
    * Draw grid.
    */
    func drawGrid() {
        if !gridVisible {
            return
        }
        drawXGrid()
        drawYGrid()
    }
    
    
    /**
    * Draw x grid.
    */
    func drawXGrid() {
        var height = self.bounds.height
        var width = self.bounds.width
        
        var space = drawingArea.width / GridLinesX
        var context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, gridColor.CGColor)
        var x:CGFloat = drawingArea.origin.x;
        var step:CGFloat = 0.0
        while step++ < GridLinesX {
            x +=  space
            CGContextMoveToPoint(context, x,  drawingArea.origin.y)
            CGContextAddLineToPoint(context, x , drawingArea.origin.y - drawingArea.height)
        }
        CGContextStrokePath(context)
    }
    
    
    
    /**
    * Draw y grid.
    */
    func drawYGrid() {
        
        var delta_h = drawingArea.height  / GridLinesY
        var context = UIGraphicsGetCurrentContext()
        var y:CGFloat = drawingArea.origin.y
        var step:CGFloat = 0.0
        while step++ < GridLinesY {
            println("drawYGrid: \(step) \(y) -> \(y-delta_h)")
            y -= delta_h
            CGContextMoveToPoint( context, drawingArea.origin.x, y )
            CGContextAddLineToPoint(context, drawingArea.origin.x + drawingArea.width, y)
            
        }
        CGContextStrokePath(context)
    }
    
    /**
    * Draw x and y axis.
    */
    func drawAxes() {
        if (!axesVisible){
            return
        }
        var height = self.bounds.height
        var width = self.bounds.width
        
        var context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, axesColor.CGColor)
        // draw x-axis
        CGContextMoveToPoint(context, drawingArea.origin.x, drawingArea.origin.y)
        CGContextAddLineToPoint(context, drawingArea.origin.x + drawingArea.width+5,  drawingArea.origin.y)
        CGContextAddLineToPoint(context, drawingArea.origin.x + drawingArea.width+5,  drawingArea.origin.y-4)
        CGContextAddLineToPoint(context, drawingArea.origin.x + drawingArea.width+5+10,  drawingArea.origin.y)
        CGContextAddLineToPoint(context, drawingArea.origin.x + drawingArea.width+5,  drawingArea.origin.y+4)
        CGContextAddLineToPoint(context, drawingArea.origin.x + drawingArea.width+5,  drawingArea.origin.y-4)

        CGContextStrokePath(context)
        // draw y-axis
        CGContextMoveToPoint(context, drawingArea.origin.x, drawingArea.origin.y)
        CGContextAddLineToPoint(context, drawingArea.origin.x, marginTop - 5.0 )
        CGContextAddLineToPoint(context, drawingArea.origin.x-4.0, marginTop - 5.0 )
        CGContextAddLineToPoint(context, drawingArea.origin.x, marginTop - 5.0 - 10.0)
        CGContextAddLineToPoint(context, drawingArea.origin.x+4.0, marginTop - 5.0 )
        CGContextAddLineToPoint(context, drawingArea.origin.x-4.0, marginTop - 5.0 )
        CGContextStrokePath(context)
        
        var xAxeTitle = UILabel(frame: CGRect(x: pointZero.x, y: height - labelAxesSize.height, width: drawingArea.width, height: labelAxesSize.height))
        xAxeTitle.font = UIFont.italicSystemFontOfSize(12.0)
        xAxeTitle.textAlignment = .Right
        xAxeTitle.text = titleForX
        self.addSubview(xAxeTitle)
        
        var yAxeTitle = UILabel(frame: CGRect(x: -labelAxesSize.height, y: pointZero.y, width: drawingArea.height, height:  labelAxesSize.height))
        yAxeTitle.font = UIFont.italicSystemFontOfSize(12.0)
        yAxeTitle.textAlignment = .Right
        yAxeTitle.text = titleForY
        yAxeTitle.backgroundColor = UIColor.clearColor()
        var yframe = yAxeTitle.frame
        yAxeTitle.layer.anchorPoint = CGPoint(x:(yframe.size.height / yframe.size.width * 0.5), y: -0.5) // Anchor points are in unit space
        yAxeTitle.frame = yframe; // Moving the anchor point moves the layer's position, this is a simple way to re-set
       yAxeTitle.transform = CGAffineTransformMakeRotation(-CGFloat(M_PI)/2)

        self.addSubview(yAxeTitle)

    }

    
    
    func calculateOffsets()  {
        offsetX = Offset(min:0.0, max:1.0)
        offsetY = Offset(min:10000.0, max:1.0)
        
        for line in collectionLines {
            println("calculateOffsets: \(line.title) [\(line.dots.count)]")

            for curr:APChartPoint in line.dots {
                
                println("calculateOffsets point:: \(curr.dot)")
                
                offsetX.updateMinMax(curr.dot.x)
                offsetY.updateMinMax(curr.dot.y)
                
            }
        }
        
        var x = offsetX.delta()/10
        offsetX.max += x
        var y = offsetY.delta()/10
        offsetY.max += y
        
        if x > 0.0 && x < offsetX.min {
            offsetX.min -= 2*y
        }
        if y > 0.0 && y < offsetY.min {
            offsetY.min -= 2*y
        }
        println("Offsets result X: \(offsetX.min) \(offsetX.max)")
        println("Offsets result Y: \(offsetY.min) \(offsetY.max)")
    }
    
    func updateLinesDataStoreScaled() {
        
        var x_factor = drawingArea.width / ( offsetX.max) // - pointZero.x )
        var y_factor = drawingArea.height /  offsetY.delta()
        var factorPoint = CGPoint(x: x_factor, y: y_factor)
        println("pointZero \(pointZero) => (x: \(pointZero.x) , y: \(pointZero.y+offsetY.min*y_factor)")

        pointBase = CGPoint(x: pointZero.x-offsetX.min*x_factor , y: pointZero.y+offsetY.min*y_factor)
        println("updateLinesDataStoreScaled  factor \(drawingArea.width) / \(( offsetX.max  )) =>  \(x_factor)")
        println("updateLinesDataStoreScaled  factor (\(x_factor),\(y_factor)), \(collectionLines.count), p0: \(pointZero))")
        for line in collectionLines {
             line.updatePoints( factorPoint, offset: pointBase )
        }
            
        
        
//        var x = linesCollection[0]
//        println("updateLinesDataStoreScaled \(x[0].x) -> \(x[0].point.x) ")
//        
        println("updateLinesDataStoreScaled end ")
    }

    /**
    * Draw x labels.
    */
    func drawXLabels() {
        if !labelsXVisible {
           return
        }
        if (offsetX.min > 0 ){
            var label = UILabel(frame: CGRect(x: pointZero.x-10.0, y: pointZero.y+8.0, width: pointZero.x-4.0, height: 16.0))
            label.backgroundColor = UIColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 0.7)
            label.font = UIFont.systemFontOfSize(10)
            label.textAlignment = NSTextAlignment.Left
            label.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * 7 / 18)
            
            label.text = "\(Int(offsetX.min))"
            self.addSubview(label)
        }
        
        var delta = drawingArea.width  / GridLinesX
        var xValue_delta = offsetX.max  / GridLinesX
        var x:CGFloat = pointZero.x
        var step:CGFloat = 0.0
        while step++ < GridLinesX {
            println("drawXGrid: \(step) \(x), \(xValue_delta*step) -> \(x+delta)")
            x += delta
            
            var label = UILabel(frame: CGRect(x: x-12.0, y: pointZero.y+12.0, width: pointZero.x-4.0-16.0, height: 16.0))
//            label.backgroundColor = UIColor(red: 0.5, green: 0.3, blue: 0.9, alpha: 0.7)
            label.font = UIFont.systemFontOfSize(10)
            label.textAlignment = NSTextAlignment.Left
            label.transform = CGAffineTransformMakeRotation(CGFloat(M_PI) * 7 / 18)

            label.text = "\(Int(xValue_delta*step))"
            self.addSubview(label)
        }

    }
    
    /**
    * Draw y labels.
    */
    func drawYLabels() {
        if !labelsYVisible{
            return
        }
        
        if (offsetY.min > 0 ) {
            var label = UILabel(frame: CGRect(x: 18.0, y:  pointZero.y-16.0, width: pointZero.x-4.0-16.0, height: 16.0))
//            label.backgroundColor = UIColor.greenColor()
            label.font = UIFont.systemFontOfSize(10)
            label.textAlignment = NSTextAlignment.Right
            label.text = "\(Int(offsetY.min))"
            self.addSubview(label)
        }
        
        var delta_h = drawingArea.height  / GridLinesY
        var yValue_delta = offsetY.delta()  / GridLinesY
        var y:CGFloat = pointZero.y
        var step:CGFloat = 0.0
        while step++ < GridLinesY {
            println("drawYGrid: \(step) \(y) -> \(y-delta_h)")
            y -= delta_h
            
            var label = UILabel(frame: CGRect(x: 18.0, y: y-8.0, width: pointZero.x-4.0-16.0, height: 16.0))
//            label.backgroundColor = UIColor.greenColor()
            label.font = UIFont.systemFontOfSize(10)
            label.textAlignment = NSTextAlignment.Right
            label.text = "\(Int(yValue_delta*step+offsetY.min))"
            self.addSubview(label)
            
            
        }
    }
    
    
    func getClosetLineDot(selectedPoint:CGPoint) -> [String:APChartPoint]?{
        println("\(drawingArea)")
//        var selectedPoint2 = CGPoint(x: selectedPoint.x - pointBase.x, y: pointBase.y - selectedPoint.y)
        println("getClosetLineDot \(selectedPoint)")
//        println("getClosetLineDot \(selectedPoint2)")
        var delta:CGFloat = 100000.0
        var diff:CGFloat = 0.0
        var selectedDot:[String:APChartPoint] = [:]
        for line in collectionLines {
            delta = 100000.0
            for (index,dot) in enumerate(line.dots){
                dot.backgroundColor = dotsBackgroundColor
                
                diff  =  selectedPoint.distanceXFrom(dot.point)
                println("-Dot \(index) - \(selectedPoint) \(dot.point)  \(dot.dot.y): \(diff)")
                if (delta > diff){
                    selectedDot[line.title] = dot
                    println("near \(index) - \(dot.point): \(diff)")
                    delta = diff
                }
            }
        }
        for (lineTitle, dot) in selectedDot {
            println("near - \(lineTitle )\(dot.point) \(dot.dot)")
            dot.backgroundColor = dotsBackgroundColor.lighterColorForColor()
        }
        return selectedDot
    }

    /**
    * Handle touch events.
    */
    func handleTouchEvents(touches: NSSet!, event: UIEvent!) {
        if (self.collectionLines.isEmpty) { return }
        
        var point: AnyObject! = touches.anyObject()
        var selectedPoint = point.locationInView(self)
        
        var bpath = UIBezierPath()
        bpath.moveToPoint(CGPoint(x: selectedPoint.x, y: marginTop))
        bpath.addLineToPoint(CGPoint(x: selectedPoint.x, y: pointZero.y))
        UIColor.grayColor().setStroke()
        bpath.stroke()
        selectetedXlayer?.removeFromSuperlayer()

        selectetedXlayer = CAShapeLayer()
        selectetedXlayer!.frame = self.bounds
        selectetedXlayer!.path = bpath.CGPath
        selectetedXlayer!.strokeColor = UIColor.purpleColor().CGColor //colors[lineIndex].CGColor
        selectetedXlayer!.fillColor = nil
        selectetedXlayer!.lineWidth = 1.0
        self.layer.addSublayer(selectetedXlayer)

        
        if let closestDots = getClosetLineDot(selectedPoint) {
            delegate?.didSelectDataPoint(closestDots)            
        }
        
    }
    
    
    /**
    * Listen on touch end event.
    */
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        handleTouchEvents(touches, event: event)
    }
    
    /**
    * Listen on touch move event
    */
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        handleTouchEvents(touches, event: event)
    }
    
}

class Offset {
    var min:CGFloat = 0.0
    var max:CGFloat = 1.0
    
    init(min:CGFloat, max:CGFloat){
        self.min = min
        self.max = max
    }
    func updateMinMax(value:CGFloat){
        if self.min > value {
            self.min = value
        }
        if self.max <  value {
            self.max = value
        }
    }
    
    func delta() -> CGFloat {
        return (self.max - self.min)
    }
}
