//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Hoyoon on 2015. 12. 20..
//  Copyright © 2015년 Fools-Gold. All rights reserved.
//

import Foundation

enum CalculatorBrainEvaluationResult {
    case Success(Double)
    case Failure(String)
}

class CalculatorBrain
{
    enum Op : CustomStringConvertible {
        case Operand(Double)
        case Variable(String)
        case Constant(String, Double)
        case UnaryOperation(String, Double -> Double)
        case BinaryOperation(String, (Double, Double) -> Double)
        
        var description: String {
            get {
                switch self {
                    case .Operand(let operand):
                        return "\(operand)"
                    case .UnaryOperation(let symbol, _):
                        return symbol
                    case .BinaryOperation(let symbol, _):
                        return symbol
                    case .Constant(let symbol, _):
                        return symbol
                    case .Variable(let symbol):
                        return symbol
                }
            }
        }
        
        var precedence: Int {
            switch self {
                case .Operand(_), .Variable(_), .Constant(_, _), .UnaryOperation(_, _):
                    return Int.max
                case .BinaryOperation("+", _), .BinaryOperation("-", _):
                    return 0
                case .BinaryOperation(_, _):
                    return Int.min
            }
        }
    }
    
    private var opStack = [Op]()
    private var knownOps = Dictionary<String, Op>()
    var variableValues = [String:Double]()
    private var error: String?
    
    init() {
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        learnOp(Op.UnaryOperation("√", sqrt))
        learnOp(Op.UnaryOperation("sin", sin))
        learnOp(Op.UnaryOperation("cos", cos))
        learnOp(Op.UnaryOperation("ᐩ/-") { -$0 })
        learnOp(Op.BinaryOperation("×", *))
        learnOp(Op.BinaryOperation("+", +))
        learnOp(Op.BinaryOperation("÷") { $1 / $0 })
        learnOp(Op.BinaryOperation("−") { $1 - $0 })
        learnOp(Op.Constant("π", M_PI))
    }
    
    var description: String {
        let (descriptionArray, _) = description([String](), ops: opStack)
        return descriptionArray.joinWithSeparator(", ")
    }
    
    var program: AnyObject {
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? [String] {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = Double(opSymbol) {
                        newOpStack.append(.Operand(operand))
                    } else {
                        newOpStack.append(.Variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    private func description(current: [String], ops: [Op]) -> (acc: [String], remainingOps: [Op]) {
        var acc = current
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeFirst()
            switch op {
                case .Operand(_), .Variable(_), .Constant(_, _):
                    acc.append(op.description)
                    return description(acc, ops: remainingOps)
                case .UnaryOperation(let symbol, _):
                    if !acc.isEmpty {
                        let unaryOperand = acc.removeLast()
                        acc.append(symbol + "(\(unaryOperand))")
                        let (newDescription, remainingOps) = description(acc, ops: remainingOps)
                        return (newDescription, remainingOps)
                    }
                case .BinaryOperation(let symbol, _):
                    if !acc.isEmpty {
                        let binaryOperandLast = acc.removeLast()
                        if !acc.isEmpty {
                            let binaryOperandFirst = acc.removeLast()
                            if op.description == remainingOps.first?.description || op.precedence >= remainingOps.first?.precedence {
                                acc.append("(\(binaryOperandFirst)" + symbol + "\(binaryOperandLast))")
                            } else {
                                acc.append("\(binaryOperandFirst)" + symbol + "\(binaryOperandLast)")
                            }
                            return description(acc, ops: remainingOps)
                        } else {
                            acc.append("?" + symbol + "\(binaryOperandLast)")
                            return description(acc, ops: remainingOps)
                        }
                    } else {
                        acc.append("?" + symbol + "?")
                        return description(acc, ops: remainingOps)
                    }
            }
        }
        return (acc, ops)
    }
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
                case .Operand(let operand):
                    return (operand, remainingOps)
                case .UnaryOperation(_, let operation):
                    let operandEvaluation = evaluate(remainingOps)
                    if let operand = operandEvaluation.result {
                        return (operation(operand), operandEvaluation.remainingOps)
                    }   else {
                        error = "Missing unary operand"
                    }
                case .BinaryOperation(_, let operation):
                    let op1Evaluation = evaluate(remainingOps)
                    if let operand1 = op1Evaluation.result {
                        let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                        if let operand2 = op2Evaluation.result {
                            return (operation(operand1, operand2), op2Evaluation.remainingOps)
                        } else {
                            error = "Missing binary operand"
                        }
                    } else {
                        error = "Missing binary operand"
                    }
                case .Constant(_, let constant):
                    return (constant, remainingOps)
                case .Variable(let symbol):
                    if let variableValue = variableValues[symbol] {
                        return (variableValue, remainingOps)
                    } else {
                        error = "\(symbol) is not set"
                        return (nil, remainingOps)
                    }
            }
        }
        return (nil, ops)
    }
    
    func evaluateAndReportErrors() -> CalculatorBrainEvaluationResult {
        if let evaluationResult = evaluate() {
            if evaluationResult.isInfinite {
                return CalculatorBrainEvaluationResult.Failure("Infinite value")
            } else if evaluationResult.isNaN {
                return CalculatorBrainEvaluationResult.Failure("Not a number")
            } else {
                return CalculatorBrainEvaluationResult.Success(evaluationResult)
            }
        } else {
            if let returnError = error {
                error = nil
                return CalculatorBrainEvaluationResult.Failure(returnError)
            } else {
                return CalculatorBrainEvaluationResult.Failure("Error")
            }
        }
    }
    
    func clearStack() {
        opStack = [Op]()
    }
    
    func removeLastOpFromStack() {
        if opStack.last != nil {
            opStack.removeLast()
        }
    }
    
    func pushOperand(operand: Double) -> CalculatorBrainEvaluationResult? {
        opStack.append(Op.Operand(operand))
        return evaluateAndReportErrors()
    }
    
    func pushOperand(symbol: String) -> CalculatorBrainEvaluationResult? {
        opStack.append(Op.Variable(symbol))
        return evaluateAndReportErrors()
    }
    
    func pushConstant(symbol: String) -> CalculatorBrainEvaluationResult? {
        if let constant = knownOps[symbol] {
            opStack.append(constant)
        }
        return evaluateAndReportErrors()
    }
    
    func performOperation(symbol: String) -> CalculatorBrainEvaluationResult? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        return evaluateAndReportErrors()
    }
    
    func evaluate() -> Double? {
        let (result, remainder) = evaluate(opStack)
        print("\(opStack) = \(result) with \(remainder) left over")
        return result
    }
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
}