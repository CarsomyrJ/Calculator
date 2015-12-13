//
//  ViewController.swift
//  Calculator
//
//  Created by Hoyoon on 2015. 12. 13..
//  Copyright (c) 2015년 Fools-Gold. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    
    var IsUserTypingDigits: Bool = false
    
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
        if(IsUserTypingDigits) {
            displayValue = -displayValue
        } else {
            if operandStack.count >= 1 {
                displayValue = -displayValue
                enter()
            }
        }
    }
    
    @IBAction func floatingMode(sender: UIButton) {
        if display.text == nil || display.text!.rangeOfString(".") == nil {
            updateDigit(sender)
        }
    }
    
    @IBAction func backspace() {
        let length = display.text!.characters.count
        if length >= 2 {
            display.text = String(display.text!.characters.dropLast())
        } else {
            display.text = "0"
        }
    }
    
    @IBAction func clear() {
        display.text = "0"
        history.text = ""
        operandStack.removeAll()
        IsUserTypingDigits = false
    }
    
    var operandStack = Array<Double>()
    
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
    
    @IBAction func operate(sender: UIButton) {
        let operation = sender.currentTitle!
        if IsUserTypingDigits {
            enter()
        }
        history.text = history.text! + " \(operation)"
        switch operation {
        case "+": performOperation {$0 + $1}
        case "−": performOperation {$1 - $0}
        case "×": performOperation {$0 * $1}
        case "÷": performOperation {$1 / $0}
        case "√": performOperation {sqrt}
        case "sin": performOperation{sin}
        case "cos": performOperation{cos}
        case "π": performOperation(M_PI)
        default: break;
        }
    }

    func performOperation(operation: (Double, Double) -> Double) {
        if operandStack.count >= 2 {
            displayValue = operation(operandStack.removeLast(), operandStack.removeLast())
            enter()
            history.text = history.text! + " =";
        }
    }
    
    private func performOperation(operation: Double -> Double) { // Function overloading is only possible in non-objC inherited classes
        if operandStack.count >= 1 {
            displayValue = operation(operandStack.removeLast())
            enter()
            history.text = history.text! + " =";
        }
    }
    
    private func performOperation(operation: Double) {
        displayValue = operation
        enter()
    }
    
    @IBAction func enter() {
        operandStack.append(displayValue!)
        history.text = history.text! + " \(displayValue!)"    // Swift 2.0 needs explicit conversion
        IsUserTypingDigits = false
        print("operandStack = \(operandStack)")         // println deprecated
    }
}
  