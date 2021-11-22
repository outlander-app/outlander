//
//  FunctionEvaluator.swift
//  Outlander
//
//  Created by Joe McBride on 11/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

struct EvalResult {
    var text: String
    var result: String
    var groups: [String]
}

class FunctionEvaluator {
    private let simplify: (String) -> String
    private let evaluator: ExpressionEvaluator

    init(_ simplify: @escaping (String) -> String) {
        self.simplify = simplify
        evaluator = ExpressionEvaluator()
    }

    func evaluateBool(_ e: Expression) -> EvalResult {
        switch e {
        case let .value(val):
            let simp = simplify(val)
            let result = evaluator.evaluateLogic(simp)
            return EvalResult(text: simp, result: "\(result)", groups: [])
        case let .function(name, args):
            let simp = simplify(args)
            let (result, groups) = executeFunction(name, simp)
            let text = "\(name)(\(simp))"
            return EvalResult(text: text, result: result, groups: groups)
        case let .expression(leftOp, op, rightOp):
            let left = evaluateBool(leftOp)
            let right = evaluateBool(rightOp)
            return evaluateBool(.value("\(left.result) \(op) \(right.result)"))
        }
    }

    func evaluateValue(_ e: Expression) -> EvalResult {
        switch e {
        case let .value(val):
            let simp = simplify(val)
            guard let result: Double = evaluator.evaluateValue(simp) else {
                return EvalResult(text: simp, result: "0", groups: [])
            }

            var res = "\(result)"

            if result == rint(result) {
                res = "\(Int(result))"
            }

            return EvalResult(text: simp, result: res, groups: [])
        case let .function(name, args):
            let simp = simplify(args)
            let (result, groups) = executeFunction(name, simp)
            let text = "\(name)(\(simp))"
            return EvalResult(text: text, result: result, groups: groups)
        case let .expression(leftOp, op, rightOp):
            let left = evaluateValue(leftOp)
            let right = evaluateValue(rightOp)
            return evaluateValue(.value("\(left.result) \(op) \(right.result)"))
        }
    }

    func executeFunction(_ funcName: String, _ argsFlat: String) -> (String, [String]) {
        let res = parseArgs(argsFlat)
        if res.count == 0 {
            return ("false", [])
        }

        let args = res.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }

        switch funcName.lowercased() {
        case "contains":
            guard args.count == 2 else { return ("false", []) }
            let result = args[0].contains(args[1])
            return ("\(result)", [])
        case "count":
            guard args.count == 2 else { return (argsFlat, []) }
            let result = args[0].components(separatedBy: args[1]).count - 1
            return ("\(result)", [])
        case "countsplit":
            guard args.count == 2 else { return (argsFlat, []) }
            let result = args[0].components(separatedBy: args[1]).count
            return ("\(result)", [])
        case "tolower":
            guard args.count == 1 else { return (argsFlat, []) }
            return (args[0].lowercased(), [])
        case "toupper", "tocaps":
            guard args.count == 1 else { return (argsFlat, []) }
            return (args[0].uppercased(), [])
        case "len", "length":
            guard args.count == 1 else { return (argsFlat, []) }
            return ("\(args[0].count)", [])
        case "endswith":
            guard args.count == 2 else { return (argsFlat, []) }
            let result = args[0].hasSuffix(args[1])
            return ("\(result)", [])
        case "startswith":
            guard args.count == 2 else { return (argsFlat, []) }
            let result = args[0].hasPrefix(args[1])
            return ("\(result)", [])
        case "trim":
            guard args.count == 1 else { return (argsFlat, []) }
            let result = args[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            return ("\(result)", [])
        default:
            return ("false", [])
        }
    }

    func parseArgs(_ args: String) -> [String] {
        var res = args[...]
        return res.parseFunctionArguments()
    }
}
