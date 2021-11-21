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
    var target: [Expression]
    var hadThen: Bool = false

    init(_ target: [Expression], text: String.SubSequence) {
        self.target = target
        self.text = text
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

        let context = ExpressionTokenizerContext([], text: text[...])

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
    override init() {
        super.init()
        push(ExpressionMode())
    }

    override func afterRead() {
        push(ExpressionMode())
    }
}

class ExpressionMode: IExpressionReaderMode {
    func read(_ context: ExpressionTokenizerContext) -> IExpressionReaderMode? {
        context.text.consumeSpaces()
        let (expression, hadThen) = context.text.parseToComponents()
        context.text.consumeSpaces()

        context.hadThen = hadThen

        context.target.append(.value(expression.trimmingCharacters(in: CharacterSet.whitespaces)))

        return nil
    }
}
