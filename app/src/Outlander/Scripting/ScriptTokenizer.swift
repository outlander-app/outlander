//
//  File.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

enum Expression: Hashable {
    case value(String)
    case function(String, String)
    indirect case expression(Expression)
}

enum ScriptTokenValue: Hashable {
    case action(String, String, String)
    case actionToggle(String, String)
    case brace(String)
    case comment(String)
    case debug(String)
    case echo(String)
    case eval(String, Expression)
    case exit
    case gosub(String, String)
    case goto(String)
    case label(String)
    case match(String, String)
    case matchre(String, String)
    case matchwait(String)
    case math(String, String, String)
    case move(String)
    case nextroom
    case pause(String)
    case put(String)
    case random(String, String)
    case `return`
    case save(String)
    case send(String)
    case shift
    case variable(String, String)
    case waitEval(String)
    case waitforPrompt(String)
    case waitfor(String)
    case waitforre(String)
}

extension ScriptTokenValue: CustomStringConvertible {
    var description: String {
        switch self {
        case .action:
            return "action"
        case .actionToggle:
            return "actiontoggle"
        case .brace:
            return "brace"
        case .comment:
            return "comment"
        case .debug:
            return "debug"
        case .echo:
            return "echo"
        case .eval:
            return "eval"
        case .exit:
            return "exit"
        case .gosub:
            return "gosub"
        case .goto:
            return "goto"
        case .label:
            return "label"
        case .match:
            return "match"
        case .matchre:
            return "matchre"
        case .matchwait:
            return "matchwait"
        case .math:
            return "math"
        case .move:
            return "move"
        case .nextroom:
            return "nextroom"
        case .pause:
            return "pause"
        case .put:
            return "put"
        case .random:
            return "random"
        case .return:
            return "return"
        case .save:
            return "save"
        case .send:
            return "send"
        case .shift:
            return "shift"
        case .variable:
            return "variable"
        case .waitEval:
            return "waiteval"
        case .waitforPrompt:
            return "wait"
        case .waitfor:
            return "waitfor"
        case .waitforre:
            return "waitforre"
        }
    }
}

extension ScriptTokenValue: Equatable {
    static func == (lhs: ScriptTokenValue, rhs: ScriptTokenValue) -> Bool {
        lhs.description == rhs.description
    }
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

    public func read(_ text: String) -> ScriptTokenValue? {
        guard modes.hasItems() else { return nil }

        let context = ScriptTokenizerContext([], text: text[...])

        startNewMode(context)

        afterRead()

        return context.target.first
    }

    func afterRead() {}

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

    override func afterRead() {
        push(CommandMode())
    }
}

class CommandMode: IScriptReaderMode {
    var knownCommands: [String: IScriptReaderMode?] = [
        "action": ActionMode(),
        "debug": DebugMode(),
        "debuglevel": DebugMode(),
        "echo": EchoMode(),
        "eval": EvalMode(),
        "exit": ExitMode(),
        "gosub": GosubMode(),
        "goto": GotoMode(),
        "match": MatchMode(),
        "matchre": MatchreMode(),
        "matchwait": MatchwaitMode(),
        "math": MathMode(),
        "move": MoveMode(),
        "nextroom": NextroomMode(),
        "pause": PauseMode(),
        "put": PutMode(),
        "random": RandomMode(),
        "return": ReturnMode(),
        "save": SaveMode(),
        "send": SendMode(),
        "shift": ShiftMode(),
        "setvariable": VariableMode(),
        "var": VariableMode(),
        "waiteval": WaitEvalMode(),
        "wait": WaitforPromptMode(),
        "waitfor": WaitforMode(),
        "waitforre": WaitforReMode(),
    ]

    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        let first = context.text.first
        guard first != nil else {
            return nil
        }

        if first == "#" {
            let text = context.text.parseToEnd()
            context.target.append(.comment(String(text)))
            return nil
        }

        let result = context.text.parseWord()
        if result.count > 0 {
            if result.last == ":" {
                context.target.append(.label(String(result.dropLast())))
                return nil
            }

            let command = String(result).lowercased()
            
            // TODO: check for if_
            
            if let mode = knownCommands[command] {
                return mode
            } else {
                return nil
            }
        }

        guard context.text.first != nil else {
            return nil
        }

        return nil
    }
}

class ActionMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd()).components(separatedBy: "when").map {
            $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }

        if rest.count == 1, let name = readName(rest[0]) {
            let toggle = rest[0].dropFirst(name.count + 2).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            context.target.append(.actionToggle(String(name), String(toggle)))
            return nil
        }

        guard rest.count > 1 else {
            return nil
        }
        if let name = readName(rest[0]) {
            let action = rest[0].dropFirst(name.count + 2).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            context.target.append(.action(name, action, rest[1]))
        }
        context.target.append(.action("", rest[0], rest[1]))
        return nil
    }

    func readName(_ rest: String) -> String? {
        if rest.hasPrefix("("), let range = rest.range(of: ")") {
            let start = rest.index(after: rest.startIndex)
            let end = rest.index(before: range.upperBound)
            return String(rest[start ..< end])
        }

        return nil
    }
}

class DebugMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.debug(rest))
        return nil
    }
}

class EchoMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.echo(rest))
        return nil
    }
}

class EvalMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        return nil
    }
}

class ExitMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.target.append(.exit)
        return nil
    }
}

class GosubMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let label = String(context.text.parseWord())
        context.text.consumeSpaces()
        let args = String(context.text.parseToEnd())
        context.target.append(.gosub(label, args))
        return nil
    }
}

class GotoMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let label = String(context.text.parseWord())
        context.target.append(.goto(label))
        return nil
    }
}

class MatchMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let label = String(context.text.parseWord())
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.match(label, rest))
        return nil
    }
}

class MatchreMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let label = String(context.text.parseWord())
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.matchre(label, rest))
        return nil
    }
}

class MatchwaitMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.matchwait(rest))
        return nil
    }
}

class MathMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let variable = context.text.parseWord()

        guard variable.count > 0 else {
            return nil
        }

        context.text.consumeSpaces()
        let action = context.text.parseWord()

        guard action.count > 0 else {
            return nil
        }

        context.text.consumeSpaces()
        let number = String(context.text.parseToEnd())

        guard number.count > 0 else {
            return nil
        }

        context.target.append(.math(String(variable), String(action), String(number)))
        return nil
    }
}

class MoveMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.move(rest))
        return nil
    }
}

class NextroomMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.target.append(.nextroom)
        return nil
    }
}

class PauseMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.pause(rest))
        return nil
    }
}

class PutMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.put(rest))
        return nil
    }
}

class RandomMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let min = String(context.text.parseWord())
        context.text.consumeSpaces()
        let max = String(context.text.parseToEnd())
        context.target.append(.random(min, max))
        return nil
    }
}

class ReturnMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.target.append(.return)
        return nil
    }
}

class SaveMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.save(rest))
        return nil
    }
}

class SendMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.send(rest))
        return nil
    }
}

class ShiftMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.target.append(.shift)
        return nil
    }
}

class VariableMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let variable = String(context.text.parseWord())
        context.text.consumeSpaces()
        let value = String(context.text.parseToEnd())
        context.target.append(.variable(variable, value))
        return nil
    }
}

class WaitEvalMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.waitEval(rest))
        return nil
    }
}

class WaitforPromptMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.waitforPrompt(rest))
        return nil
    }
}

class WaitforMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.waitfor(rest))
        return nil
    }
}

class WaitforReMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let rest = String(context.text.parseToEnd())
        context.target.append(.waitforre(rest))
        return nil
    }
}
