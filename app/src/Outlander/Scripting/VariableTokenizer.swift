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

    public static func splitToVariables(_ input: String) -> [String] {
        var results: [String] = []

        func isVariable(_ char: Character?) -> Bool {
            char == "$" || char == "%" || char == "&"
        }

        func isSpace(_ char: Character) -> Bool {
            char == " " || char == "\t"
        }

        var current = ""

        for c in input {
            if isSpace(c), !current.isEmpty {
                results.append(current)
                current = ""
            }

            if isVariable(c), !current.isEmpty {
                results.append(current)
                current = ""
            }

            current += String(c)
        }

        if !current.isEmpty {
            results.append(current)
        }

        return results
    }
}

class IndexedVariableMode: IVariableReaderMode {
    func read(_ context: VariableTokenizerContext) -> IVariableReaderMode? {
        let input = String(context.text.parseToEnd())
        let regex = RegexFactory.get("([%$&][a-zA-Z0-9_\\.\\-$%&]+)[\\[(]([a-zA-Z0-9\\._\\-$%&]+)[\\])]")!
        let matches = regex.allMatches(input)

        guard matches.count > 0 else {
            context.target.append(.value(input))
            return nil
        }

        var start = input.startIndex

        for match in matches {
            guard let range = match.rangeOf(index: 0) else {
                continue
            }
            if range.lowerBound != start {
                let str = String(input[start ..< range.lowerBound])
                context.target.append(.value(str))
            }

            let variable = match.valueAt(index: 1) ?? ""
            let idx = match.valueAt(index: 2) ?? ""

            context.target.append(.indexed(variable, idx))

            start = range.upperBound
        }

        if start != input.endIndex {
            let str = String(input[start ..< input.endIndex])
            context.target.append(.value(str))
        }

        return nil
    }
}
