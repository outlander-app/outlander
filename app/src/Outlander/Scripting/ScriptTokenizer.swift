//
//  File.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

enum Expression {
    case value(String)
    case function(String, String)
    indirect case expression(Expression)
}

enum ScriptTokenValue: Hashable {
    case comment(String)
    case echo(String)
    case exit
    case label(String)
}

protocol IScriptReaderMode: AnyObject {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode?
}

class ScriptTokenizerContext {
    var text: String.SubSequence
    var target: [ScriptTokenValue]

    init(_ target: [ScriptTokenValue], text: String.SubSequence) {
        self.target = target
        self.text = text
    }
}

class ScriptReaderBase<T> {
    private var modes: Stack<IScriptReaderMode>

    init(target: T) {
        modes = Stack<IScriptReaderMode>()
        self.target = target
    }

    public var target: T

    var current: IScriptReaderMode? { modes.peek() }

    public func push(_ mode: IScriptReaderMode) {
        modes.push(mode)
    }

    public func read(_ text: String) -> [ScriptTokenValue] {
        guard modes.hasItems() else { return [] }

        let context = ScriptTokenizerContext([], text: text[...])

        startNewMode(context)

//        push(TextMode())

        return context.target
    }

    func startNewMode(_ context: ScriptTokenizerContext) {
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

class ScriptTokenizer: ScriptReaderBase<[ScriptTokenValue]> {
    init() {
        super.init(target: [])
        push(CommandMode())
    }
}

class CommandMode: IScriptReaderMode {
    var knownCommands = ["echo"]

    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        if context.text.first == "#" {
            let text = context.text.parseToEnd()
            context.target.append(ScriptTokenValue.comment(String(text)))
            return nil
        }

        let result = context.text.parseWord()
        if result.count > 0 {
            print(result)
            if result.last == ":" {
                context.target.append(ScriptTokenValue.label(String(result.dropLast())))
            }

            let command = String(result).lowercased()
            if knownCommands.contains(command) {
                context.text.consumeSpaces()
                let rest = String(context.text.parseToEnd())
                context.target.append(ScriptTokenValue.echo(rest))
            }
        }

        guard context.text.first != nil else {
            return nil
        }

        return nil
    }
}
