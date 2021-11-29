//
//  File.swift
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
        if let b = input.toBool() {
            return b
        }

        let result: String? = evaluate(input)
        return result?.lowercased() == "true"
    }

    func evaluateValue(_ input: String) -> Double? {
        let res: String? = evaluate(input)
        return Double(res ?? "")
    }

    func evaluate<T>(_ input: String) -> T? {
        do {
            let result: T? = try AnyExpression(
                input: input
            ).evaluate()
            return result
        } catch {
            print("AnyExpression Error: \(error) for input \(input)")
            log.error("AnyExpression Error: \(error) for input \(input)")
            return nil
        }
    }
}

public extension AnyExpression {
    init(
        input: String,
        symbols: [Symbol: SymbolEvaluator] = [:]
    ) {
        let replaced = AnyExpression.replaceSingleOperators(input)
//        print("AnyExpression input: \(input)")
//        print("AnyExpression replaced: \(replaced)")
        let exp = Expression.parse(replaced, usingCache: true)
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
                            return lhs == 0 ? true : false
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("Arguments \(types) are not compatible with \(symbol)")
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
                            return lhs == 0 ? false : true
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("Arguments \(types) are not compatible with \(symbol)")
                        }
                    }
                case .infix("="):
                    return { args in
                        switch (args[0], args[1]) {
                        case let (lhs as Bool, rhs as Bool):
                            return lhs == rhs
                        case let (lhs as Double, rhs as Double):
                            return lhs == rhs
                        case let (lhs as Double, rhs as Bool):
                            return lhs != 0 && rhs
                        case let (lhs as Bool, rhs as Double):
                            return lhs && rhs != 0
                        case let (lhs as String, rhs as Bool):
                            return lhs.toBool() == true && rhs
                        case let (lhs as Bool, rhs as String):
                            return lhs && rhs.toBool() == true
                        case let (lhs as String, rhs as String):
                            return lhs == rhs
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("Arguments \(types) are not compatible with \(symbol)")
                        }
                    }
                case .infix("&&"):
                    return { args in
                        switch (args[0], args[1]) {
                        case let (lhs as Bool, rhs as Bool):
                            return lhs && rhs
                        case let (lhs as Double, rhs as Double):
                            return lhs != 0 && rhs != 0
                        case let (lhs as Double, rhs as Bool):
                            return lhs != 0 && rhs
                        case let (lhs as Bool, rhs as Double):
                            return lhs && rhs != 0
                        case let (lhs as String, rhs as Bool):
                            return lhs.toBool() == true && rhs
                        case let (lhs as Bool, rhs as String):
                            return lhs && rhs.toBool() == true
                        case let (lhs as String, rhs as String):
                            return lhs.toBool() == true && rhs.toBool() == true
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("Arguments \(types) are not compatible with \(symbol)")
                        }
                    }
                case .infix("||"):
                    return { args in
                        switch (args[0], args[1]) {
                        case let (lhs as Bool, rhs as Bool):
                            return lhs || rhs
                        case let (lhs as Double, rhs as Double):
                            return lhs != 0 || rhs != 0
                        case let (lhs as Double, rhs as Bool):
                            return lhs != 0 || rhs
                        case let (lhs as Bool, rhs as Double):
                            return lhs || rhs != 0
                        case let (lhs as String, rhs as Bool):
                            return lhs.toBool() == true || rhs
                        case let (lhs as Bool, rhs as String):
                            return lhs || rhs.toBool() == true
                        case let (lhs as String, rhs as String):
                            return lhs.toBool() == true || rhs.toBool() == true
                        default:
                            let types = args.map { "\(type(of: $0))" }.joined(separator: ", ")
                            throw Expression.Error.message("Arguments \(types) are not compatible with \(symbol)")
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
