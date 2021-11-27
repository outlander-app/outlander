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
    var groups: [String] = []

    func evaluateLogic(_ input: ScriptExpression) -> Bool {
        switch input {
        case let .value(val):
            return evaluateLogic(val)
        }
    }

    func evaluateValue(_ input: ScriptExpression) -> Double? {
        switch input {
        case let .value(val):
            return evaluateValue(val)
        }
    }

    func evaluateStrValue(_ input: ScriptExpression) -> String? {
        switch input {
        case let .value(val):
            return evaluate(val)
        }
    }

    func evaluateLogic(_ input: String) -> Bool {
        if let b = input.toBool() {
            return b
        }

        let result: String? = evaluate(input)
        return result == "true"
    }

    func evaluateValue(_ input: String) -> Double? {
        let res: String? = evaluate(input)
        return Double(res ?? "")
    }

    func evaluate<T>(_ input: String) -> T? {
        do {
            let result: T? = try AnyExpression(
                input: input,
                symbols: buildSymbols()
            ).evaluate()
            return result
        } catch {
            print("AnyExpression Error: \(error) for input \(input)")
            return nil
        }
    }

    func buildSymbols() -> [Expression.Symbol: (_ args: [Any]) throws -> Any] {
        [
            .function("contains", arity: 2): { args in
                let res = self.trimQuotes(args[0]).contains(self.trimQuotes(args[1]))
                return res ? "true" : "false"
            },
            .function("count", arity: 2): { args in
                let res = self.trimQuotes(args[0]).components(separatedBy: self.trimQuotes(args[1])).count - 1
                return "\(res)"
            },
            .function("countsplit", arity: 2): { args in
                let res = self.trimQuotes(args[0]).components(separatedBy: self.trimQuotes(args[1])).count
                return "\(res)"
            },
            .function("length", arity: 1): { args in
                "\(self.trimQuotes(args[0]).count)"
            },
            .function("len", arity: 1): { args in "\(self.trimQuotes(args[0]).count)" },
            .function("matchre", arity: 2): { args in
                var source = self.trimQuotes(args[0])
                let pattern = self.trimQuotes(args[1])
                guard let regex = RegexFactory.get(pattern) else {
                    return source
                }

                if let match = regex.firstMatch(&source) {
                    print("matchre groups \(match.values())")
                    self.groups = match.values()
                    return match.count > 0 ? "true" : "false"
                }

                return "false"
            },
            .function("tolower", arity: 1): { args in self.trimQuotes(args[0]).lowercased() },
            .function("toupper", arity: 1): { args in self.trimQuotes(args[0]).uppercased() },
            .function("tocaps", arity: 1): { args in self.trimQuotes(args[0]).uppercased() },
            .function("trim", arity: 1): { args in self.trimQuotes(args[0]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) },
            .function("replace", arity: 3): { args in
                let source = self.trimQuotes(args[0])
                let pattern = self.trimQuotes(args[1])
                let replacement = self.trimQuotes(args[2])
                let result = source.replacingOccurrences(of: pattern, with: replacement)
                return result
            },
            .function("replacere", arity: 3): { args in
                let source = self.trimQuotes(args[0])
                let pattern = self.trimQuotes(args[1])
                let replacement = self.trimQuotes(args[2])
                guard let regex = RegexFactory.get(pattern) else {
                    return source
                }
                let result = regex.replace(source, with: replacement)
                return result
            },
            .function("startswith", arity: 2): { args in
                self.trimQuotes(args[0]).hasPrefix(self.trimQuotes(args[1]))
                    ? "true" : "false"
            },
            .function("endswith", arity: 2): { args in self.trimQuotes(args[0]).hasSuffix(self.trimQuotes(args[1])) ? "true" : "false" },
        ]
    }

    func trimQuotes(_ input: Any) -> String {
        String(describing: input).trimmingCharacters(in: CharacterSet(["\""]))
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
        let exp = Expression.parse(replaced, usingCache: false)
        self.init(
            exp,
            impureSymbols: { symbol in
                switch symbol {
//                case .infix("="):
//                    return {args in
//                        false
//                    }
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
