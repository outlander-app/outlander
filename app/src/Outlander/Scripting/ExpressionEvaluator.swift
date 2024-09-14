//
//  ExpressionEvaluator.swift
//  Outlander
//
//  Created by Joe McBride on 11/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Expression
import Foundation

class ExpressionEvaluator {
    let log: ILogger

    var groups: [String] = []

    private var exp: AnyExpression?

    init() {
        log = LogManager.getLog(String(describing: type(of: self)))
    }

    func evaluateLogic(_ input: ScriptExpression) -> Bool {
        switch input {
        case let .value(val):
            return evaluateLogic(val)
        default:
            return false
        }
    }

    func evaluateValue(_ input: ScriptExpression) -> Double? {
        switch input {
        case let .value(val):
            return evaluateValue(val)
        default:
            return nil
        }
    }

    func evaluateStrValue(_ input: ScriptExpression) -> String? {
        switch input {
        case let .value(val):
            return evaluate(val)
        default:
            return nil
        }
    }

    func evaluateLogic(_ input: String) -> Bool {
        guard input.count >= 0 else {
            return false
        }

        if let b = input.toBool() {
            return b
        }

        let result: String? = evaluate(input)
        return result?.lowercased() == "true"
    }

    func evaluateValue(_ input: String) -> Double? {
        if input.isEmpty {
            return nil
        }
        let res: String? = evaluate(input)
        return Double(res ?? "")
    }

    func evaluate<T>(_ input: String) -> T? {
        if input.isEmpty {
            return nil
        }
        do {
            exp = AnyExpression(input: input)
            let result: T? = try exp?.evaluate()
            return result
        } catch {
            print("AnyExpression Error: \(error) for input \(input)")
            log.error("AnyExpression Error: \(error) for input \(input)")
            return nil
        }
    }

    static func replaceSingleOperators(_ input: String) -> String {
        let operators = [
            "=",
            // trying to replace these cause problems
//            "&",
//            "\\|",
        ]

        var result = input

        for op in operators {
            let exp = "((?<![!<>\(op)])\(op)(?!\(op)))"
            guard let regex = RegexFactory.get(exp) else {
                continue
            }

            result = regex.replace(result, with: "\(op)\(op)")
        }

        return result
    }
}

public extension AnyExpression {
    init(
        input: String,
        symbols: [Symbol: SymbolEvaluator] = [:]
    ) {
//        print("evaluating \(input)")
        let replaced = ExpressionEvaluator.replaceSingleOperators(input)
        let exp = Expression.parse(replaced, usingCache: true)
        
        func equalBools(a: Bool?, b: Bool?) -> Bool {
            guard let a = a, let b = b else {
                return false
            }

            return a == b
        }
        
        func andBools(a: Bool?, b: Bool?) -> Bool {
            guard let a = a, let b = b else {
                return false
            }

            return a && b
        }

        func orBools(a: Bool?, b: Bool?) -> Bool {
            return a == true || b == true
        }
        
        self.init(
            exp,
            impureSymbols: { symbol in
                switch symbol {
                case .prefix("!"):
                    return { args in
                        switch args[0] {
                        case let lhs as Bool:
                            return !lhs
                        case let lhs as String:
                            return !(lhs.toBool() == true)
                        case let lhs as Double:
                            return !(lhs.toBool() == true)
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("! arguments \(types) are not compatible with \(symbol)")
                        }
                    }
                case .prefix("!!"):
                    return { args in
                        switch args[0] {
                        case let lhs as Bool:
                            return lhs
                        case let lhs as String:
                            return lhs.toBool() == true
                        case let lhs as Double:
                            return lhs.toBool() == true
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("!! arguments \(types) are not compatible with \(symbol)")
                        }
                    }
                case .infix("="):
                    fallthrough
                case .infix("=="):
                    return { args in
                        switch (args[0], args[1]) {
                        case let (lhs as Bool, rhs as Bool):
                            return lhs == rhs
                        case let (lhs as Double, rhs as Double):
                            return lhs == rhs
                        case let (lhs as Double, rhs as Bool):
                            return equalBools(a: lhs.toBool(), b: rhs)
                        case let (lhs as Bool, rhs as Double):
                            return equalBools(a: lhs, b: rhs.toBool())
                        case let (lhs as String, rhs as Bool):
                            return equalBools(a: lhs.toBool(), b: rhs)
                        case let (lhs as Bool, rhs as String):
                            return equalBools(a: lhs, b: rhs.toBool())
                        case let (lhs as String, rhs as Double):
                            let equal = lhs == "\(rhs)"
                            guard !equal else { return true }
                            return equalBools(a: lhs.toBool(), b: rhs.toBool())
                        case let (lhs as Double, rhs as String):
                            let equal = "\(lhs)" == rhs
                            guard !equal else { return true }
                            return equalBools(a: lhs.toBool(), b: rhs.toBool())
                        case let (lhs as String, rhs as String):
                            return lhs == rhs || equalBools(a: lhs.toBool(), b: rhs.toBool())
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("== arguments \(types) are not compatible with \(symbol)")
                        }
                    }
                case .infix("&&"):
                    return { args in
                        switch (args[0], args[1]) {
                        case let (lhs as Bool, rhs as Bool):
                            return lhs && rhs
                        case let (lhs as Double, rhs as Double):
                            return andBools(a: lhs.toBool(), b: rhs.toBool())
                        case let (lhs as Double, rhs as Bool):
                            return andBools(a: lhs.toBool(), b: rhs)
                        case let (lhs as Bool, rhs as Double):
                            return andBools(a: lhs, b: rhs.toBool())
                        case let (lhs as String, rhs as Bool):
                            return andBools(a: lhs.toBool(), b: rhs)
                        case let (lhs as Bool, rhs as String):
                            return andBools(a: lhs, b: rhs.toBool())
                        case let (lhs as String, rhs as Double):
                            return andBools(a: lhs.toBool(), b: rhs.toBool())
                        case let (lhs as Double, rhs as String):
                            return andBools(a: lhs.toBool(), b: rhs.toBool())
                        case let (lhs as String, rhs as String):
                            return andBools(a: lhs.toBool(), b: rhs.toBool())
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("&& arguments \(types) are not compatible with \(symbol)")
                        }
                    }
                case .infix("||"):
                    return { args in
                        switch (args[0], args[1]) {
                        case let (lhs as Bool, rhs as Bool):
                            return lhs || rhs
                        case let (lhs as Double, rhs as Double):
                            return orBools(a: lhs.toBool(), b: rhs.toBool())
                        case let (lhs as Double, rhs as Bool):
                            return orBools(a: lhs.toBool(), b: rhs)
                        case let (lhs as Bool, rhs as Double):
                            return orBools(a: lhs, b: rhs.toBool())
                        case let (lhs as String, rhs as Bool):
                            return orBools(a: lhs.toBool(), b: rhs)
                        case let (lhs as Bool, rhs as String):
                            return orBools(a: lhs, b: rhs.toBool())
                        case let (lhs as String, rhs as Double):
                            return orBools(a: lhs.toBool(), b: rhs.toBool())
                        case let (lhs as Double, rhs as String):
                            return orBools(a: lhs.toBool(), b: rhs.toBool())
                        case let (lhs as String, rhs as String):
                            return orBools(a: lhs.toBool(), b: rhs.toBool())
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("|| arguments \(types) are not compatible with \(symbol)")
                        }
                    }
                case let .variable(name):
                    return { _ in name }
                case let .function(name, arity: arity):
                    return symbols[.function(name.lowercased(), arity: arity)]
                default:
                    return symbols[symbol]
                }
            },
            pureSymbols: { symbol in
                switch symbol {
                case let .variable(name):
                    return { _ in name }
                default:
                    return symbols[symbol]
                }
            }
        )
    }
}
