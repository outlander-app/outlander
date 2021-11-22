//
//  ExpressionTokenizer.swift
//  Outlander
//
//  Created by Joe McBride on 11/21/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

protocol IExpressionReaderMode: AnyObject {
    func read(_ context: ExpressionTokenizerContext) -> IExpressionReaderMode?
}

class ExpressionTokenizerContext {
    var text: String.SubSequence
    var originalText: String
    var target: [Expression]
    var hadThen: Bool = false

    init(_ target: [Expression], text: String.SubSequence, originalText: String) {
        self.target = target
        self.text = text
        self.originalText = originalText
    }
}

struct ExpressionTokenizerResult {
    var expression: Expression?
    var rest: String
    var hadThen: Bool
}

class ExpressionReaderBase<T> {
    private var modes: Stack<IExpressionReaderMode>

    var current: IExpressionReaderMode? { modes.peek() }

    init() {
        modes = Stack<IExpressionReaderMode>()
    }

    public func push(_ mode: IExpressionReaderMode) {
        modes.push(mode)
    }

    public func read(_ text: String) -> ExpressionTokenizerResult {
        guard modes.hasItems() else { return ExpressionTokenizerResult(expression: nil, rest: "", hadThen: false) }

        let context = ExpressionTokenizerContext([], text: text[...], originalText: text)

        startNewMode(context)

        afterRead()

        let rest = String(context.text)

        return ExpressionTokenizerResult(expression: context.target.first, rest: rest, hadThen: context.hadThen)
    }

    func afterRead() {}

    func startNewMode(_ context: ExpressionTokenizerContext) {
        guard modes.hasItems() else { return }

        let next = current?.read(context)

        guard let nextMode = next else {
            _ = modes.pop()
            startNewMode(context)
            return
        }

        if nextMode !== current {
            modes.push(nextMode)
            startNewMode(context)
        }
    }
}

class ExpressionTokenizer: ExpressionReaderBase<[Expression]> {
    private var initialMode: IExpressionReaderMode

    init(_ initialMode: IExpressionReaderMode = ExpressionBodyMode()) {
        self.initialMode = initialMode
        super.init()
        push(initialMode)
    }

    override func afterRead() {
        push(initialMode)
    }
}

let knownFunctions = [
    "contains",
    "count",
    "countsplit",
    "tolower",
    "tocaps",
    "toupper",
    "len",
    "length",
    "endswith",
    "startswith",
    "trim",
]

class ExpressionBodyMode: IExpressionReaderMode {
    func read(_ context: ExpressionTokenizerContext) -> IExpressionReaderMode? {
        context.text.consumeSpaces()

        let (expression, hadThen) = context.text.parseToComponents()
        context.text.consumeSpaces()

        context.hadThen = hadThen

        let result = ExpressionTokenizer(ExpressionMode()).read(expression.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))

        guard let exp = result.expression else {
            return nil
        }

        context.target.append(exp)

        return nil
    }
}

class ExpressionMode: IExpressionReaderMode {
    func read(_ context: ExpressionTokenizerContext) -> IExpressionReaderMode? {
        context.text.consumeSpaces()

        var list: [Expression] = []

        while context.text.count > 0 {
            if let exp = context.text.parseExpression(knownFunctions) {
                list.append(exp)
            } else {
                return nil
            }
        }

        if let res = Expression.combine(tags: list) {
            context.target.append(res)
        }

        return nil
    }
}
