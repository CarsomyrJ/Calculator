//
//  HappinessViewController.swift
//  Happiness
//
//  Created by CS193p Instructor.
//  Copyright (c) 2015 Stanford University. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource
{
    var program: AnyObject?
    
    func updateUI() {
        graphView.setNeedsDisplay()
    }
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: "scale:"))
        }
    }
    
    func graphPlot(sender: GraphView) -> [(x: Double, y: Double)]? {
        let brain = CalculatorBrain()
        var plots = [(x: Double, y: Double)]()
        //let width = view.bounds.size.width
        if let program = program {
            brain.program = program
            for x in -200...200 {
                brain.variableValues["M"] = Double(x)
                let evaluationResult = brain.evaluateAndReportErrors()
                switch evaluationResult {
                    case let .Success(y):
                        if y.isNormal || y.isZero {
                            plots.append((x: Double(x), y: y))
                        }
                    default: break
                }
            }
        }
        return plots
    }
    
    
}
