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

    func evaluateBool(_ e: ScriptExpression) -> EvalResult {
        switch e {
        case let .value(val):
            let simp = simplify(val)
            let result = evaluator.evaluateLogic(simp)
            return EvalResult(text: simp, result: "\(result)", groups: evaluator.groups)
        default:
            return EvalResult(text: "", result: "", groups: [])
        }
    }

    func evaluateStrValue(_ e: ScriptExpression) -> EvalResult {
        switch e {
        case let .value(val):
            let simp = simplify(val)
            guard let result: String? = evaluator.evaluate(simp) else {
                return EvalResult(text: simp, result: "0", groups: evaluator.groups)
            }

            return EvalResult(text: simp, result: result ?? "", groups: [])
        default:
            return EvalResult(text: "", result: "", groups: [])
        }
    }

    func evaluateValue(_ e: ScriptExpression) -> EvalResult {
        switch e {
        case let .value(val):
            let simp = simplify(val)
            guard let result = evaluator.evaluateValue(simp) else {
                return EvalResult(text: simp, result: "0", groups: [])
            }

            var res = "\(result)"

            if result == rint(result) {
                res = "\(Int(result))"
            }

            return EvalResult(text: simp, result: res, groups: evaluator.groups)
        default:
            return EvalResult(text: "", result: "", groups: [])
        }
    }
}
