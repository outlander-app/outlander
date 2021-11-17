//
//  VariableTokenizer.swift
//  Outlander
//
//  Created by Joe McBride on 11/16/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

enum VariableToken {
    case value(String)
    case indexed(String, String)
}

protocol IVariableReaderMode: AnyObject {
    func read(_ context: VariableTokenizerContext) -> IVariableReaderMode?
}

class VariableTokenizerContext {
    var text: String.SubSequence
    var target: [VariableToken]

    init(_ target: [VariableToken], text: String.SubSequence) {
        self.target = target
        self.text = text
    }
}

class VariableReaderBase<T> {
    private var modes: Stack<IVariableReaderMode>

    init(target: T) {
        modes = Stack<IVariableReaderMode>()
        self.target = target
    }

    public var target: T

    var current: IVariableReaderMode? { modes.peek() }

    public func push(_ mode: IVariableReaderMode) {
        modes.push(mode)
    }

    public func read(_ text: String) -> [VariableToken] {
        guard modes.hasItems() else { return [] }

        let context = VariableTokenizerContext([], text: text[...])

        startNewMode(context)

        afterRead()

        return context.target
    }

    func afterRead() {}

    func startNewMode(_ context: VariableTokenizerContext) {
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

class VariableTokenizer: VariableReaderBase<[VariableToken]> {
    init() {
        super.init(target: [])
        push(IndexedVariableMode())
    }

    override func afterRead() {
        push(IndexedVariableMode())
    }
}

class IndexedVariableMode: IVariableReaderMode {
    func read(_ context: VariableTokenizerContext) -> IVariableReaderMode? {
        for v in context.text.parseIndexedVariables() {
            context.target.append(v)
        }
        return nil
    }
}
