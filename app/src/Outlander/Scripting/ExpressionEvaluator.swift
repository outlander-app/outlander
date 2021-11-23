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
        evaluate(input)
    }

    func evaluate<T>(_ input: String) -> T? {
        do {
            let result: T? = try AnyExpression(
                input: input,
                symbols: buildSymbols()
            ).evaluate()
            return result
        } catch {
            print("error \(error)")
            return nil
        }
    }

    func buildSymbols() -> [Expression.Symbol: (_ args: [Any]) throws -> Any] {
        [
            .function("tolower", arity: 1): { args in String(describing: args[0]).lowercased() },
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
        self.init(
            Expression.parse(replaced),
            impureSymbols: { symbol in
                switch symbol {
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
            "&",
            "\\|",
        ]

        var result = input

        for op in operators {
            let exp = "((?<![\(op)])\(op)(?!\(op)))"
            guard let regex = RegexFactory.get(exp) else {
                continue
            }

            result = regex.replace(result, with: "\(op)\(op)")
        }

        return result
    }
}
