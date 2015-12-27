//
//  ViewController.swift
//  Calculator
//
//  Created by Hoyoon on 2015. 12. 13..
//  Copyright (c) 2015년 Fools-Gold. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    
    var IsUserTypingDigits: Bool = false
    private let defaultHistoryText = " "
    
    let brain = CalculatorBrain()
    
    private struct DefaultDisplayResult {
        static let Startup: Double = 0
        static let Error = "Error!"
    }
    
    @IBAction func updateDigit(sender: UIButton) {
        let digit = sender.currentTitle!
        if(IsUserTypingDigits) {
            display.text = display.text! + digit
        } else {
            display.text = digit
            IsUserTypingDigits = true
        }
    }
    
    @IBAction func updateSign() {
        if IsUserTypingDigits {
            if displayValue != nil {
                displayResult = CalculatorBrainEvaluationResult.Success(displayValue! * -1)
                IsUserTypingDigits = true
            }
        } else {
            displayResult = brain.performOperation("ᐩ/-")
        }
    }
  
    @IBAction func backspace() {
        if IsUserTypingDigits == true {
            if display.text!.characters.count > 1 {
                display.text = String(display.text!.characters.dropLast())
            } else {
                displayResult = CalculatorBrainEvaluationResult.Success(DefaultDisplayResult.Startup)
            }
        } else {
            brain.removeLastOpFromStack()
            displayResult = brain.evaluateAndReportErrors()
        }
    }
    
    @IBAction func pi() {
        if IsUserTypingDigits {
            enter()
        }
        displayResult = brain.pushConstant("π")
    }
    
    @IBAction func setM() {
        IsUserTypingDigits = false
        if displayValue != nil {
            brain.variableValues["M"] = displayValue!
        }
        displayResult = brain.evaluateAndReportErrors()
    }
    
    @IBAction func getM() {
        if IsUserTypingDigits {
            enter()
        }
        displayResult = brain.pushOperand("M")
    }
    
    @IBAction func clear() {
        brain.clearStack()
        brain.variableValues.removeAll()
        displayResult = CalculatorBrainEvaluationResult.Success(DefaultDisplayResult.Startup)
        history.text = defaultHistoryText
    }
    
    var displayValue: Double? {
        get {
            return Double(display.text!)        // Swift 2 Double fallable initializer
        }
        set {
            if newValue == nil {
                display.text = "0"
            } else {
                display.text = "\(newValue!)"
                IsUserTypingDigits = false
            }
        }
    }
    
    var displayResult: CalculatorBrainEvaluationResult? {
        get {
            if let displayValue = displayValue {
                return .Success(displayValue)
            }
            if display.text != nil {
                return .Failure(display.text!)
            }
            return .Failure("Error")
        }
        set {
            if newValue != nil {
                switch newValue! {
                case let .Success(displayValue):
                    display.text = "\(displayValue)"
                case let .Failure(error):
                    display.text = error
                }
            } else {
                display.text = DefaultDisplayResult.Error
            }
            IsUserTypingDigits = false
            
            if !brain.description.isEmpty {
                history.text = " \(brain.description) ="
            } else {
                history.text = defaultHistoryText
            }
        }
    }
    
    @IBAction func operate(sender: UIButton) {
        if IsUserTypingDigits {
            enter()
        }
        if let operation = sender.currentTitle {
            displayResult = brain.performOperation(operation)
        }
    }

    @IBAction func enter() {
        IsUserTypingDigits = false
        if displayValue != nil {
            displayResult = brain.pushOperand(displayValue!)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination: UIViewController? = segue.destinationViewController
        if let navCon = destination as? UINavigationController {
            destination = navCon.visibleViewController
        }
        if let gvc = destination as? GraphViewController {
            gvc.program = brain.program
        }
    }
}
  