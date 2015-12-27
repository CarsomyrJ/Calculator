//
//  GraphView.swift
//  Happiness
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func graphPlot(sender: GraphView) -> [(x: Double, y: Double)]?
}

@IBDesignable
class GraphView: UIView
{
    @IBInspectable
    var color: UIColor = UIColor.blueColor() { didSet { setNeedsDisplay() } }
    @IBInspectable
    var plotColor: UIColor = UIColor.redColor() { didSet { setNeedsDisplay() } }
    @IBInspectable
    var scale: CGFloat = 1.0 { didSet { setNeedsDisplay() } }
    
    let pointsPerUnit: CGFloat = 50.0
    
    private var graphCenter: CGPoint {
        return convertPoint(center, fromView: superview)
    }
    
    weak var dataSource: GraphViewDataSource?
  
    func scale(gesture: UIPinchGestureRecognizer) {
        if gesture.state == .Changed {
            scale *= gesture.scale
            gesture.scale = 1
        }
    }
    
    private func translatePlot(plot: (x: Double, y: Double)) -> CGPoint {
        let translatedX = CGFloat(plot.x)  + graphCenter.x
        let translatedY = CGFloat(-plot.y) + graphCenter.y
        return CGPoint(x: translatedX, y: translatedY)
    }
    
    override func drawRect(rect: CGRect)
    {
        let axes = AxesDrawer(color: color, contentScaleFactor: contentScaleFactor)
        axes.drawAxesInRect(bounds, origin: graphCenter, pointsPerUnit: 1)
        
        let bezierPath = UIBezierPath()
        
        if var plots = dataSource?.graphPlot(self) where plots.first != nil {
            bezierPath.moveToPoint(translatePlot((x: plots.first!.x, y: plots.first!.y)))
            plots.removeFirst()
            for plot in plots {
                bezierPath.addLineToPoint(translatePlot((x: plot.x, y: plot.y)))
            }
        }
        
        plotColor.set()
        bezierPath.stroke()
    }    
}
