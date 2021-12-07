//
//  File.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

enum ScriptExpression: Hashable {
    case value(String)
    case function(String, [String])
    case values([ScriptExpression])

    func combine(with other: ScriptExpression) -> [ScriptExpression] {
        switch self {
        case let .value(txt):
            switch other {
            case let .value(otherTxt):
                if txt.hasSuffix("(") || otherTxt == "(" {
                    return [.value(txt + otherTxt)]
                }

                if otherTxt.hasAnyPrefix(["!", "="]) {
                    return [.value(txt.hasAnySuffix(["!", "="]) ? txt + otherTxt : "\(txt) \(otherTxt)")]
                }

                return [.value("\(txt) \(otherTxt)")]
            default:
                return [self, other]
            }
        default:
            return [self, other]
        }
    }

    static func combine(expressions: [ScriptExpression]) -> [ScriptExpression] {
        let combined = expressions.reduce([ScriptExpression]()) { list, next in

            if let last = list.last {
                return list.dropLast() + last.combine(with: next)
            }

            return [next]
        }

        return combined
    }
}

extension ScriptExpression: CustomStringConvertible {
    var description: String {
        switch self {
        case let .value(str):
            return str
        case let .function(name, args):
            return "\(name)(\(args.joined(separator: ", "))"
        case let .values(values):
            return values.map { $0.description }.joined(separator: " ")
        }
    }
}

enum ScriptTokenValue: Hashable {
    case action(String, String, String)
    case actionToggle(String, String)
    case leftBrace
    case rightBrace
    case comment(String)
    case debug(String)
    case echo(String)
    indirect case elseIfSingle(ScriptExpression, ScriptTokenValue)
    case elseIf(ScriptExpression)
    case elseIfNeedsBrace(ScriptExpression)
    case `else`
    indirect case elseSingle(ScriptTokenValue)
    case elseNeedsBrace
    case eval(String, ScriptExpression)
    case evalMath(String, ScriptExpression)
    case exit
    indirect case ifArgSingle(Int, ScriptTokenValue)
    case ifArg(Int)
    case ifArgNeedsBrace(Int)
    indirect case ifSingle(ScriptExpression, ScriptTokenValue)
    case `if`(ScriptExpression)
    case ifNeedsBrace(ScriptExpression)
    case gosub(String, String)
    case goto(String, String)
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
    case unvar(String)
    case variable(String, String)
    case waitEval(String)
    case waitforPrompt(String)
    case waitfor(String)
    case waitforre(String)

    var isTopLevelIf: Bool {
        switch self {
        case .ifArg: return true
        case .ifArgSingle: return true
        case .ifArgNeedsBrace: return true
        case .ifSingle: return true
        case .if: return true
        case .ifNeedsBrace: return true
        default: return false
        }
    }

    var ifHasBody: Bool {
        switch self {
        case .ifArg: return true
        case .ifArgNeedsBrace: return true
        case .if: return true
        case .ifNeedsBrace: return true
        default: return false
        }
    }

    var isIfToken: Bool {
        switch self {
        case .ifArg: return true
        case .ifArgSingle: return true
        case .ifArgNeedsBrace: return true
        case .ifSingle: return true
        case .if: return true
        case .ifNeedsBrace: return true
        case .elseIfSingle: return true
        case .elseIf: return true
        case .elseIfNeedsBrace: return true
        default: return false
        }
    }

    var isElseIfToken: Bool {
        switch self {
        case .elseIfSingle: return true
        case .elseIf: return true
        case .elseIfNeedsBrace: return true
        default: return false
        }
    }

    var isElseToken: Bool {
        switch self {
        case .elseSingle: return true
        case .else: return true
        case .elseNeedsBrace: return true
        default: return false
        }
    }

    var isSingleToken: Bool {
        switch self {
        case .ifArgSingle: return true
        case .ifSingle: return true
        case .elseIfSingle: return true
        case .elseSingle: return true
        default: return false
        }
    }

    var isSingleElseIfOrElseToken: Bool {
        switch self {
        case .elseIfSingle: return true
        case .elseSingle: return true
        default: return false
        }
    }
}

extension ScriptTokenValue: CustomStringConvertible {
    var description: String {
        switch self {
        case .action:
            return "action"
        case .actionToggle:
            return "actiontoggle"
        case .leftBrace:
            return "leftbrace"
        case .rightBrace:
            return "rightbrace"
        case .comment:
            return "comment"
        case .debug:
            return "debug"
        case .echo:
            return "echo"
        case .elseIfSingle:
            return "elseifsingle"
        case .elseIf:
            return "elseif"
        case .elseIfNeedsBrace:
            return "elseifneedsbrace"
        case .else:
            return "else"
        case .elseSingle:
            return "elsesingle"
        case .elseNeedsBrace:
            return "elseneedsbrace"
        case .eval:
            return "eval"
        case .evalMath:
            return "evalmath"
        case .exit:
            return "exit"
        case .ifArgSingle:
            return "ifargsingle"
        case .ifArg:
            return "ifarg"
        case .ifArgNeedsBrace:
            return "ifargneedsbrace"
        case .ifSingle:
            return "ifsingle"
        case .if:
            return "if"
        case .ifNeedsBrace:
            return "ifneedsbrace"
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
        case .unvar:
            return "unvar"
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
        "{": LeftBraceMode(),
        "}": RightBraceMode(),
        "action": ActionMode(),
        "debug": DebugMode(),
        "debuglevel": DebugMode(),
        "echo": EchoMode(),
        "eval": EvalMode(),
        "evalmath": EvalMode(),
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
        "unvar": UnVarMode(),
        "setvariable": VariableMode(),
        "var": VariableMode(),
        "waiteval": WaitEvalMode(),
        "wait": WaitforPromptMode(),
        "waitfor": WaitforMode(),
        "waitforre": WaitforReMode(),
    ]

    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeWhitespace()

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

            guard !command.hasPrefix("if_") else {
                return IfArgMode(command)
            }

            guard !command.hasPrefix("if") else {
                return IfMode(command)
            }

            guard !command.hasPrefix("else") else {
                return ElseMode()
            }

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
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if rest.count == 1, let name = readName(rest[0]) {
            let toggle = rest[0].dropFirst(name.count + 2).trimmingCharacters(in: .whitespacesAndNewlines)
            context.target.append(.actionToggle(String(name), String(toggle)))
            return nil
        }

        guard rest.count > 1 else {
            return nil
        }
        if let name = readName(rest[0]) {
            let action = rest[0].dropFirst(name.count + 2).trimmingCharacters(in: .whitespacesAndNewlines)
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

class LeftBraceMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()

        guard context.text.count == 0 else {
            return CommandMode()
        }

        context.target.append(.leftBrace)

        return nil
    }
}

class RightBraceMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()

        guard context.text.count == 0 else {
            return CommandMode()
        }

        context.target.append(.rightBrace)

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

class ElseIfMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        let result = ExpressionTokenizer().read(String(context.text.parseToEnd()))

        guard let expression = result.expression else {
            return nil
        }

        var rest = result.rest

        let surrounded = rest.hasPrefix("{") && rest.hasSuffix("}")

        if surrounded {
            rest = rest.trimmingCharacters(in: CharacterSet(["{", "}", " "]))
        }

        if rest != "{", surrounded || result.hadThen, let token = ScriptTokenizer().read(rest) {
            context.target.append(.elseIfSingle(expression, token))
            return nil
        }

        if rest == "{" {
            context.target.append(.elseIf(expression))
        } else {
            context.target.append(.elseIfNeedsBrace(expression))
        }

        return nil
    }
}

class ElseMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeWhitespace()

        let maybeThen = String(context.text.parseWord())

        if maybeThen == "if" {
            return ElseIfMode()
        }

        let maybeBrace = String(context.text.parseToEnd()).trimmingCharacters(in: .whitespacesAndNewlines)

        if maybeThen == "then" && maybeBrace != "{", let token = ScriptTokenizer().read(maybeBrace) {
            context.target.append(.elseSingle(token))
            return nil
        }

        var fullText = "\(maybeThen) \(maybeBrace)".trimmingCharacters(in: .whitespacesAndNewlines)
        let surrounded = fullText.hasPrefix("{") && fullText.hasSuffix("}")

        if !surrounded && (maybeThen == "{" || maybeBrace == "{") {
            context.target.append(.else)
            return nil
        }

        if surrounded {
            fullText = fullText.trimmingCharacters(in: CharacterSet(["{", "}", " "]))
        }

        if maybeBrace != "{", let token = ScriptTokenizer().read(fullText) {
            context.target.append(.elseSingle(token))
            return nil
        }

        guard fullText == "then" || fullText.count == 0 else {
            return nil
        }

        context.target.append(.elseNeedsBrace)

        return nil
    }
}

class EvalMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let variable = String(context.text.parseWord())
        context.text.consumeSpaces()
        let expressionBody = String(context.text.parseToEnd())

        let result = ExpressionTokenizer().read(expressionBody)

        guard let expression = result.expression else {
            return nil
        }

        context.target.append(.eval(variable, expression))
        return nil
    }
}

class EvalMathMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let variable = String(context.text.parseWord())
        context.text.consumeSpaces()
        let expressionBody = String(context.text.parseToEnd())

        let result = ExpressionTokenizer().read(expressionBody)

        guard let expression = result.expression else {
            return nil
        }

        context.target.append(.evalMath(variable, expression))
        return nil
    }
}

class ExitMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.target.append(.exit)
        return nil
    }
}

class IfArgMode: IScriptReaderMode {
    let input: String

    init(_ input: String) {
        self.input = input
    }

    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        guard let number = Int(input.dropFirst(3)) else {
            return nil
        }

        context.text.consumeSpaces()
        let maybeThen = String(context.text.parseWord())
        let rest = String(context.text.parseToEnd())
        let restTrimmed = rest.trimmingCharacters(in: .whitespacesAndNewlines)

        let surrounded = (maybeThen == "{" && rest.hasSuffix("}")) || (restTrimmed.hasPrefix("{") && rest.hasSuffix("}"))

        if surrounded {
            let start = maybeThen == "then" ? "" : maybeThen
            let txt = (start + rest).trimmingCharacters(in: CharacterSet([" ", "{", "}"]))
            if let token = ScriptTokenizer().read(txt) {
                context.target.append(.ifArgSingle(number, token))
                return nil
            }
        }

        if maybeThen == "{" || (maybeThen == "then" && restTrimmed == "{") {
            context.target.append(.ifArg(number))
            return nil
        }

        if maybeThen == "then", let token = ScriptTokenizer().read(restTrimmed) {
            context.target.append(.ifArgSingle(number, token))
            return nil
        }

        if maybeThen == "then", restTrimmed.count == 0 {
            context.target.append(.ifArgNeedsBrace(number))
            return nil
        }

        if let token = ScriptTokenizer().read((maybeThen + rest).trimmingCharacters(in: .whitespaces)) {
            context.target.append(.ifArgSingle(number, token))
            return nil
        }

        if maybeThen.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 {
            context.target.append(.ifArgNeedsBrace(number))
            return nil
        }

        return nil
    }
}

class IfMode: IScriptReaderMode {
    var input: String

    init(_ input: String) {
        self.input = input
    }

    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        let start = String(input.dropFirst(2))
        let tokenizer = ExpressionTokenizer()
        let result = tokenizer.read(String(start + context.text.parseToEnd()))

        guard let expression = result.expression else {
            return nil
        }

        var rest = result.rest.trimmingCharacters(in: .whitespaces)

        let surrounded = rest.hasPrefix("{") && rest.hasSuffix("}")

        if surrounded {
            rest = rest.trimmingCharacters(in: CharacterSet(["{", "}", " "]))
        }

        if rest != "{", surrounded || result.hadThen, let token = ScriptTokenizer().read(rest) {
            context.target.append(.ifSingle(expression, token))
            return nil
        }

        if rest == "{" {
            context.target.append(.if(expression))
        } else {
            context.target.append(.ifNeedsBrace(expression))
        }

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
        context.text.consumeSpaces()
        let args = String(context.text.parseToEnd())
        context.target.append(.goto(label, args))
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

class UnVarMode: IScriptReaderMode {
    func read(_ context: ScriptTokenizerContext) -> IScriptReaderMode? {
        context.text.consumeSpaces()
        let variable = String(context.text.parseWord())
        context.target.append(.unvar(variable))
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
