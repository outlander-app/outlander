//
//  ScriptOperations.swift
//  Outlander
//
//  Created by Joe McBride on 2/26/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

enum CheckStreamResult {
    case match(String)
    case none
}

class ActionOp: IAction {
    var id: String
    var enabled: Bool

    var name: String
    var command: String
    var pattern: String

    var groups: [String]

    var line: ScriptLine

    init(name: String, command: String, pattern: String, line: ScriptLine) {
        id = UUID().uuidString
        enabled = true

        self.name = name
        self.command = command
        self.pattern = pattern
        self.line = line

        groups = []
    }

    func stream(_ text: String, _: [StreamCommand], _ context: ScriptContext) -> CheckStreamResult {
        guard pattern.count > 0 else {
            return .none
        }

        let resolvedPattern = context.replaceVars(pattern)
        let regex = RegexFactory.get(resolvedPattern)
        var input = text
        
        if let matches = regex?.allMatches(&input) {
            for match in matches {
                print(match.values())
            }
        }

        if let match = regex?.firstMatch(&input) {
            groups = match.values()
            return .match("action (line \(line.lineNumber)) triggered by: \(text)")
        }

        return .none
    }

    func execute(_ script: Script, _ context: ScriptContext) {
        context.setActionVars(groups)
        let commands = context.replaceActionVars(command).commandsSeperated()

        let tokenizer = ScriptTokenizer()

        for command in commands {
            guard let token = tokenizer.read(command) else {
                continue
            }

            let result = script.executeToken(line, token)
            switch result {
            case .next:
                guard case .goto = token else {
                    continue
                }
                script.next()
            case .exit: script.cancel()
            default: continue
            }
        }
    }
}

class MoveOp: IWantStreamInfo {
    var id = ""

    init() {
        id = UUID().uuidString
    }

    func stream(_: String, _ commands: [StreamCommand], _: ScriptContext) -> CheckStreamResult {
        for cmd in commands {
            switch cmd {
            case .compass:
                return .match("")
            default:
                continue
            }
        }

        return .none
    }

    func execute(_ script: Script, _: ScriptContext) {
        script.next()
    }
}

class NextRoomOp: IWantStreamInfo {
    var id = ""

    init() {
        id = UUID().uuidString
    }

    func stream(_: String, _ commands: [StreamCommand], _: ScriptContext) -> CheckStreamResult {
        for cmd in commands {
            switch cmd {
            case .compass:
                return .match("")
            default:
                continue
            }
        }

        return .none
    }

    func execute(_ script: Script, _: ScriptContext) {
        script.nextAfterRoundtime()
    }
}

class WaitEvalOp: IWantStreamInfo {
    var id = ""
    private let evaluator: ExpressionEvaluator
    private let expression: String

    init(_ expression: String) {
        id = UUID().uuidString
        evaluator = ExpressionEvaluator()
        self.expression = expression
    }

    func stream(_: String, _ commands: [StreamCommand], _ context: ScriptContext) -> CheckStreamResult {
        for cmd in commands {
            switch cmd {
            case .prompt:
                let simplified = context.replaceVars(expression)
                if evaluator.evaluateLogic(simplified) {
                    return .match("waiteval \(simplified) = true")
                }
            default:
                continue
            }
        }
        return .none
    }

    func execute(_ script: Script, _: ScriptContext) {
        script.nextAfterRoundtime()
    }
}

class WaitforPromptOp: IWantStreamInfo {
    var id = ""

    init() {
        id = UUID().uuidString
    }

    func stream(_: String, _ commands: [StreamCommand], _: ScriptContext) -> CheckStreamResult {
        for cmd in commands {
            switch cmd {
            case .prompt:
                return .match("")
            default:
                continue
            }
        }

        return .none
    }

    func execute(_ script: Script, _: ScriptContext) {
        script.nextAfterRoundtime()
    }
}

class WaitforOp: IWantStreamInfo {
    var id = ""
    let target: String

    init(_ target: String) {
        id = UUID().uuidString
        self.target = target
    }

    func stream(_ text: String, _: [StreamCommand], _ context: ScriptContext) -> CheckStreamResult {
        let check = context.replaceVars(target)
        return text.range(of: check) != nil
            ? .match(text)
            : .none
    }

    func execute(_ script: Script, _: ScriptContext) {
        script.next()
    }
}

class WaitforReOp: IWantStreamInfo {
    public var id = ""
    var pattern: String
    var groups: [String]

    init(_ pattern: String) {
        id = UUID().uuidString
        self.pattern = pattern
        groups = []
    }

    func stream(_ text: String, _: [StreamCommand], _ context: ScriptContext) -> CheckStreamResult {
        let resolved = context.replaceVars(pattern)
        var txt = text

        let regex = RegexFactory.get(resolved)
        guard let match = regex?.firstMatch(&txt) else {
            return .none
        }
        groups = match.values()
        return groups.count > 0 ? .match(txt) : .none
    }

    func execute(_ script: Script, _ context: ScriptContext) {
        context.setRegexVars(groups)
        script.next()
    }
}
