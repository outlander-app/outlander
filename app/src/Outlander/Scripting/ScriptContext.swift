//
//  ScriptContext.swift
//  Outlander
//
//  Created by Joe McBride on 11/21/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class ScriptContext {
    private var context: GameContext
    private var tokenizer: ScriptTokenizer

    var lines: [ScriptLine] = []
    var labels: [String: Label] = [:]
    var variables = Variables(eventKey: "")
    var args: [String] = []
    var argumentVars = Variables(eventKey: "")
    var actionVars = Variables(eventKey: "")
    var labelVars = Variables(eventKey: "")
    var regexVars = Variables(eventKey: "")
    var currentLineNumber: Int = -1

    var ifStack = Stack<ScriptLine>()
    var ifResultStack = Stack<Bool>()

    var currentLine: ScriptLine? {
        if currentLineNumber < 0 || currentLineNumber >= lines.count {
            return nil
        }

        return lines[currentLineNumber]
    }

    var previousLine: ScriptLine? {
        if currentLineNumber - 1 < 0 {
            return nil
        }

        return lines[currentLineNumber - 1]
    }

    var roundtime: Double? {
        Double(context.globalVars["roundtime"] ?? "")
    }

    init(context: GameContext) {
        self.context = context
        tokenizer = ScriptTokenizer()
    }

    func advance() {
        currentLineNumber += 1
    }

    func retreat() {
        currentLineNumber -= 1
    }

    func advanceToNextBlock() -> Bool {
        guard let target = ifStack.last else {
            return false
        }

        while currentLineNumber < lines.count {
            advance()

            guard let line = currentLine else {
                return false
            }

            guard let currentIf = ifStack.last else {
                return false
            }

            if line.token == nil {
                line.token = tokenizer.read(line.originalText)
            }

            guard let lineToken = line.token else {
                continue
            }

            switch lineToken {
            case .rightBrace:
                if currentIf.lineNumber == target.lineNumber {
                    return true
                }

                let (popped, _) = popIfStack()
                if !popped {
                    return false
                }
            default:
                if lineToken.isTopLevelIf && !lineToken.isSingleToken {
                    pushCurrentLineToIfStack()
                }

                continue
            }
        }

        return false
    }

    func advanceToEndOfBlock() -> Bool {
        while currentLineNumber < lines.count {
            advance()

            guard let line = currentLine else {
                return false
            }

            if line.token == nil {
                line.token = tokenizer.read(line.originalText)
            }

            guard let lineToken = line.token else {
                return false
            }

            if !ifStack.hasItems() && lineToken.isTopLevelIf {
                retreat()
                return true
            }

            if lineToken.isSingleToken {
                continue
            }

            if lineToken.isIfToken || lineToken.isElseToken {
                pushCurrentLineToIfStack()
                if !advanceToNextBlock() {
                    return false
                }
                continue
            } else {
                retreat()
                return true
            }
        }

        return false
    }

    func consumeToken(_ token: ScriptTokenValue) -> Bool {
        advance()
        return expecting(token: token)
    }

    func expecting(token: ScriptTokenValue) -> Bool {
        guard let line = currentLine else {
            return false
        }

        if line.token == nil {
            line.token = tokenizer.read(line.originalText)
        }

        guard let t = line.token else {
            return false
        }

        return token == t
    }

    func replaceVars(_ input: String) -> String {
        let context = VariableContext()
        context.add("$", values: { key in self.labelVars[key] })
        context.add("$", values: { key in self.regexVars[key] })
        context.add("%", values: { key in self.variables[key] })
        context.add("%", values: { key in self.argumentVars[key] })
        context.add("$", values: { key in self.context.globalVars[key] })
        return VariableReplacer().replace(input, context: context)
    }

    func replaceActionVars(_ input: String) -> String {
        let context = VariableContext()
        context.add("$", values: { key in self.actionVars[key] })
        context.add("%", values: { key in self.variables[key] })
        context.add("%", values: { key in self.argumentVars[key] })
        context.add("$", values: { key in self.context.globalVars[key] })
        return VariableReplacer().replace(input, context: context)
    }

    func setRegexVars(_ vars: [String]) {
        regexVars.removeAll()
        for (index, param) in vars.enumerated() {
            regexVars["\(index)"] = param
        }
    }

    func setActionVars(_ vars: [String]) {
        regexVars.removeAll()
        for (index, param) in vars.enumerated() {
            actionVars["\(index)"] = param
        }
    }

    func setLabelVars(_ vars: [String]) {
        labelVars.removeAll()
        for (index, param) in vars.enumerated() {
            labelVars["\(index)"] = param
        }
    }

    func setArgumentVars(_ args: [String]) {
        self.args = args
        argumentVars.removeAll()

        if args.count > 0 {
            argumentVars["0"] = args.joined(separator: " ")
            for (index, param) in args.enumerated() {
                argumentVars["\(index + 1)"] = param.trimmingCharacters(in: CharacterSet(["\""]))
            }
        } else {
            argumentVars["0"] = ""
        }

        let originalCount = self.args.count

        let maxArgs = 9

        let diff = maxArgs - originalCount

        if diff > 0 {
            let start = maxArgs - diff
            for index in start ..< maxArgs {
                argumentVars["\(index + 1)"] = ""
            }
        }

        variables["argcount"] = "\(originalCount)"
    }

    func shiftArgs() {
        guard args.count > 0 else {
            return
        }
        setArgumentVars(Array(args.dropFirst()))
    }

    @discardableResult func pushCurrentLineToIfStack() -> Bool {
        guard let line = currentLine else {
            return false
        }

        pushLineToIfStack(line)
        return true
    }

    func pushLineToIfStack(_ line: ScriptLine) {
        ifStack.push(line)
    }

    @discardableResult func popIfStack() -> (Bool, ScriptLine?) {
        guard ifStack.hasItems() else {
            return (false, nil)
        }

        let line = ifStack.pop()
        return (true, line)
    }
}
