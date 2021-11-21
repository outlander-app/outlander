//
//  Script.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

func delay(_ delay: Double, queue: DispatchQueue = DispatchQueue.main, _ closure: @escaping () -> Void) -> DispatchWorkItem {
    let task = DispatchWorkItem { closure() }
    // TODO: swap from main queue?
    queue.asyncAfter(deadline: .now() + delay, execute: task)
    return task
}

public enum ScriptLogLevel: Int {
    case none = 0
    case gosubs = 1
    case wait = 2
    case `if` = 3
    case vars = 4
    case actions = 5
}

struct Label {
    var name: String
    var line: Int
    var scriptLine: Int
    var fileName: String
}

class GosubContext {
    var label: Label
    var line: ScriptLine
    var arguments: [String]
    var isGosub: Bool
    var returnToLine: ScriptLine?
    var returnToIndex: Int?
    var ifStack: Stack<ScriptLine>

    init(label: Label, line: ScriptLine, arguments: [String], ifStack: Stack<ScriptLine>, isGosub: Bool) {
        self.label = label
        self.line = line
        self.arguments = arguments
        self.ifStack = ifStack
        self.isGosub = isGosub
    }
}

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

        if let endOfBlock = target.endOfBlock {
            currentLineNumber = endOfBlock
            return true
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

            if lineToken.isIfToken || lineToken.isElseToken {
                if currentIf.lineNumber == target.lineNumber {
                    // popIfStack()
                    currentIf.endOfBlock = currentLineNumber - 1
                    retreat()
                    return true
                } else {
                    pushCurrentLineToIfStack()
                }
            }

            switch lineToken {
            case .rightBrace:
                if currentIf.lineNumber == target.lineNumber {
                    // popIfStack()
                    currentIf.endOfBlock = currentLineNumber
                    return true
                }

                let (popped, _) = popIfStack()
                if !popped {
                    return false
                }
            default:
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
        context.add("$", sortedKeys: regexVars.keys, values: { key in self.regexVars[key] })
        context.add("$", sortedKeys: labelVars.keys, values: { key in self.labelVars[key] })
        context.add("%", sortedKeys: variables.keys, values: { key in self.variables[key] })
        context.add("%", sortedKeys: argumentVars.keys, values: { key in self.argumentVars[key] })
        context.add("$", sortedKeys: self.context.globalVars.keys, values: { key in self.context.globalVars[key] })
        return VariableReplacer().replace(input, context: context)
    }

    func replaceActionVars(_ input: String) -> String {
        let context = VariableContext()
        context.add("$", sortedKeys: actionVars.keys, values: { key in self.actionVars[key] })
        context.add("%", sortedKeys: variables.keys, values: { key in self.variables[key] })
        context.add("%", sortedKeys: argumentVars.keys, values: { key in self.argumentVars[key] })
        context.add("$", sortedKeys: self.context.globalVars.keys, values: { key in self.context.globalVars[key] })
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

class ScriptLine {
    var originalText: String
    var fileName: String
    var lineNumber: Int
    var token: ScriptTokenValue?
    var endOfBlock: Int?
    var ifResult: Bool?

    init(_ originalText: String, fileName: String, lineNumber: Int) {
        self.originalText = originalText
        self.fileName = fileName
        self.lineNumber = lineNumber
    }
}

protocol IScriptLoader {
    func exists(_ file: String) -> Bool
    func load(_ fileName: String) -> [String]
}

class InMemoryScriptLoader: IScriptLoader {
    var lines: [String: [String]] = [:]

    func exists(_: String) -> Bool {
        lines.count > 0
    }

    func load(_ fileName: String) -> [String] {
        lines[fileName]!
    }
}

class ScriptLoader: IScriptLoader {
    private var files: FileSystem
    private var settings: ApplicationSettings

    init(_ files: FileSystem, settings: ApplicationSettings) {
        self.files = files
        self.settings = settings
    }

    func exists(_ file: String) -> Bool {
        let fileUrl = settings.paths.scripts.appendingPathComponent("\(file).cmd")
        return files.fileExists(fileUrl)
    }

    func load(_ file: String) -> [String] {
        let fileUrl = settings.paths.scripts.appendingPathComponent("\(file).cmd")

        guard let data = files.load(fileUrl) else {
            return []
        }

        guard let fileString = String(data: data, encoding: .utf8) else {
            return []
        }

        return fileString.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: .newlines)
    }
}

enum ScriptExecuteResult {
    case next
    case wait
    case exit
    case advanceToNextBlock
    case advanceToEndOfBlock
}

protocol IWantStreamInfo {
    var id: String { get }
    func stream(_ text: String, _ tokens: [StreamCommand], _ context: ScriptContext) -> CheckStreamResult
    func execute(_ script: Script, _ context: ScriptContext)
}

protocol IAction: IWantStreamInfo {
    var name: String { get set }
    var enabled: Bool { get set }
}

@propertyWrapper
struct Atomic<Value> {
    private let lock = DispatchSemaphore(value: 1)
    private var value: Value

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
        get {
            lock.wait()
            defer { lock.signal() }
            return value
        }
        set {
            lock.wait()
            value = newValue
            lock.signal()
        }
    }
}

class Script {
    private let lockQueue = DispatchQueue(label: "com.outlanderapp.script.\(UUID().uuidString)", attributes: .concurrent)

    var started: Date?
    var fileName: String = ""
    var debugLevel = ScriptLogLevel.none

    private var stackTrace: Stack<ScriptLine>
    private var tokenHandlers: [String: (ScriptLine, ScriptTokenValue) -> ScriptExecuteResult]
    private var reactToStream: [IWantStreamInfo] = []
    private var actions: [IAction] = []

    private var gosubStack: Stack<GosubContext>

    @Atomic() private var matchStack: [IMatch] = []
    @Atomic() private var matchwait: Matchwait? = nil

    private var lastLine: ScriptLine? {
        stackTrace.last2
    }

    private var lastTokenWasIf: Bool {
        guard let lastToken = lastLine?.token else {
            return false
        }

        return lastToken.isIfToken
    }

    var stopped = false
    var paused = false
    var nextAfterUnpause = false

    var tokenizer: ScriptTokenizer
    var loader: IScriptLoader
    var context: ScriptContext
    var gameContext: GameContext
    let funcEvaluator: FunctionEvaluator

    var includeRegex: Regex
    var labelRegex: Regex

    var delayedTask: DispatchWorkItem?

    static var dateFormatter = DateFormatter()

    init(_ fileName: String, loader: IScriptLoader, gameContext: GameContext) throws {
        self.fileName = fileName
        self.loader = loader
        self.gameContext = gameContext

        tokenizer = ScriptTokenizer()

        stackTrace = Stack<ScriptLine>(30)
        gosubStack = Stack<GosubContext>(101)

        includeRegex = RegexFactory.get("^\\s*include (.+)$")!
        labelRegex = RegexFactory.get("^\\s*(\\w+((\\.|-|\\w)+)?):")!

        context = ScriptContext(context: gameContext)
        context.variables["scriptname"] = fileName
        funcEvaluator = FunctionEvaluator(context.replaceVars)

        // eval
        // eval math
        tokenHandlers = [:]
        tokenHandlers["action"] = handleAction
        tokenHandlers["actiontoggle"] = handleActionToggle
        tokenHandlers["leftbrace"] = handleLeftBrace
        tokenHandlers["rightbrace"] = handleRightBrace
        tokenHandlers["comment"] = handleComment
        tokenHandlers["debug"] = handleDebug
        tokenHandlers["echo"] = handleEcho
        tokenHandlers["eval"] = handleEval
        tokenHandlers["exit"] = handleExit

        tokenHandlers["ifarg"] = handleIfArg
        tokenHandlers["ifargsingle"] = handleIfArgSingle
        tokenHandlers["ifargneedsbrace"] = handleIfArgNeedsBrace

        tokenHandlers["if"] = handleIf
        tokenHandlers["ifsingle"] = handleIfSingle
        tokenHandlers["ifneedsbrace"] = handleIfNeedsBrace

        tokenHandlers["elseif"] = handleElseIf
        tokenHandlers["elseifsingle"] = handleElseIfSingle
        tokenHandlers["elseifneedsbrace"] = handleElseIfNeedsBrace

        tokenHandlers["else"] = handleElse
        tokenHandlers["elsesingle"] = handleElseSingle
        tokenHandlers["elseneedsbrace"] = handleElseNeedsBrace

        tokenHandlers["gosub"] = handleGosub
        tokenHandlers["goto"] = handleGoto
        tokenHandlers["label"] = handleLabel
        tokenHandlers["match"] = handleMatch
        tokenHandlers["matchre"] = handleMatchre
        tokenHandlers["matchwait"] = handleMatchwait
        tokenHandlers["math"] = handleMath
        tokenHandlers["move"] = handleMove
        tokenHandlers["nextroom"] = handleNextroom
        tokenHandlers["pause"] = handlePause
        tokenHandlers["put"] = handlePut
        tokenHandlers["random"] = handleRandom
        tokenHandlers["return"] = handleReturn
        tokenHandlers["save"] = handleSave
        tokenHandlers["send"] = handleSend
        tokenHandlers["shift"] = handleShift
        tokenHandlers["unvar"] = handleUnVar
        tokenHandlers["variable"] = handleVariable
        tokenHandlers["waiteval"] = handleWaitEval
        tokenHandlers["wait"] = handleWaitforPrompt
        tokenHandlers["waitfor"] = handleWaitfor
        tokenHandlers["waitforre"] = handleWaitforRe

        Script.dateFormatter.dateFormat = "hh:mm a"
    }

    deinit {
        self.gameContext.events.unregister(self)
    }

    func run(_ args: [String], runAsync: Bool = true) {
        func doRun() {
            started = Date()

            let formattedDate = Script.dateFormatter.string(from: started!)

            sendText("[Starting '\(fileName)' at \(formattedDate)]")

            context.setArgumentVars(args)

            initialize(fileName)

            next()
        }

        if runAsync {
            lockQueue.async {
                doRun()
            }
        } else {
            doRun()
        }
    }

    func next() {
        if stopped { return }

        if paused {
            nextAfterUnpause = true
            return
        }

        context.advance()

        guard let line = context.currentLine else {
            cancel()
            return
        }

        if line.token == nil {
            line.token = tokenizer.read(line.originalText)
        }

        stackTrace.push(line)

        let result = handleLine(line)

        switch result {
        case .next: next()
        case .wait: return
        case .exit: cancel()
        case .advanceToNextBlock:
            if context.advanceToNextBlock() {
                next()
            } else {
                if let line = context.currentLine {
                    sendText("Unable to match next if block", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
                }
                cancel()
            }
        case .advanceToEndOfBlock:
            if context.advanceToEndOfBlock() {
                next()
            } else {
                if let line = context.currentLine {
                    sendText("Unable to match end of block", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
                }
                cancel()
            }
        }
    }

    func nextAfterRoundtime() {
        if let roundtime = context.roundtime {
            if roundtime > 0 {
                delayedTask = delay(roundtime, queue: lockQueue) {
                    self.nextAfterRoundtime()
                }
                return
            }
        }

        next()
    }

    func pause() {
        paused = true
        sendText("[Pausing '\(fileName)']")
    }

    func resume() {
        if !paused {
            return
        }

        sendText("[Resuming '\(fileName)']")

        paused = false

        if nextAfterUnpause {
            next()
        }
    }

    func cancel() {
        stop()
    }

    private func stop() {
        delayedTask?.cancel()

        if stopped { return }

        stopped = true
        context.currentLineNumber = -1

        let diff = Date().timeIntervalSince(started!)
        sendText("[Script '\(fileName)' completed after \(diff.formatted)]")

        gameContext.events.unregister(self)
        gameContext.events.post("ol:script:complete", data: fileName)
    }

    func stream(_ text: String, _ tokens: [StreamCommand]) {
        guard text.count > 0 || tokens.count > 0, !paused, !stopped else {
            return
        }

        _ = checkActions(text, tokens)

        let handlers = reactToStream.filter { x in
            let res = x.stream(text, tokens, self.context)
            switch res {
            case let .match(txt):
                notify("matched \(txt)", debug: .wait)
                return true
            default:
                return false
            }
        }

        handlers.forEach { handler in
            guard let idx = reactToStream.firstIndex(where: { $0.id == handler.id }) else {
                return
            }
            reactToStream.remove(at: idx)
            handler.execute(self, context)
        }

        checkMatches(text)
    }

    private func checkActions(_ text: String, _ tokens: [StreamCommand]) -> Bool {
        let actions = self.actions.filter { a in
            guard a.enabled else {
                return false
            }

            let result = a.stream(text, tokens, context)
            switch result {
            case let .match(txt):
                notify(txt, debug: .actions)
                return true
            case .none:
                return false
            }
        }

        for action in actions {
            action.execute(self, context)
        }

        return actions.count > 0
    }

    private func checkMatches(_ text: String) {
        guard let _ = matchwait else {
            return
        }

        var foundMatch: IMatch?

        for match in matchStack {
            if match.isMatch(text, context) {
                foundMatch = match
                break
            }
        }

        guard let match = foundMatch else {
            return
        }

        matchwait = nil
        matchStack.removeAll()

        let label = context.replaceVars(match.label)

        notify("match \(label)", debug: ScriptLogLevel.wait, scriptLine: match.lineNumber)
        let result = gotoLabel(label, match.groups)

        switch result {
        case .exit: cancel()
        case .next: nextAfterRoundtime()
        default: return
        }
    }

    private func sendText(_ text: String, preset: String = "scriptinput", scriptLine: Int = -1, fileName: String = "") {
        guard fileName.count > 0 else {
            gameContext.events.echoText("\(text)", preset: preset, mono: true)
            return
        }

        let name = fileName == "" ? self.fileName : fileName
        let display = scriptLine > -1 ? "[\(name)(\(scriptLine))]: \(text)" : "[\(name)]: \(text)"

        gameContext.events.echoText(display, preset: preset, mono: true)
    }

    private func notify(_ text: String, debug: ScriptLogLevel, preset: String = "scriptinfo", scriptLine: Int = -1, fileName: String = "") {
        guard debugLevel.rawValue >= debug.rawValue else {
            return
        }

        let name = fileName == "" ? self.fileName : fileName

        let display = scriptLine > -1 ? "[\(name)(\(scriptLine))]: \(text)" : "[\(name)]: \(text)"

        gameContext.events.echoText(display, preset: preset)
    }

    private func initialize(_ fileName: String) {
        let lines = loader.load(fileName)

        if lines.count == 0 {
            sendText("Script '\(fileName)' is empty or does not exist", preset: "scripterror")
            return
        }

        var index = 0

        for var line in lines {
            index += 1

            if line == "" {
                continue
            }

            if let includeMatch = includeRegex.firstMatch(&line) {
                guard let include = includeMatch.valueAt(index: 1) else { continue }
                let includeName = include.trimmingCharacters(in: CharacterSet.whitespaces)
                guard includeName != fileName else {
                    sendText("script '\(fileName)' cannot include itself!", preset: "scripterror", scriptLine: index, fileName: fileName)
                    continue
                }
                notify("including '\(includeName)'", debug: ScriptLogLevel.gosubs, scriptLine: index)
                initialize(includeName)
            } else {
                let scriptLine = ScriptLine(
                    line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                    fileName: fileName,
                    lineNumber: index
                )

                context.lines.append(scriptLine)
            }

            if let labelMatch = labelRegex.firstMatch(&line) {
                guard let label = labelMatch.valueAt(index: 1) else { return }
                let newLabel = Label(name: label.lowercased(), line: context.lines.count - 1, scriptLine: index, fileName: fileName)
                if let existing = context.labels[label] {
                    sendText("replacing label '\(existing.name)' at line \(existing.scriptLine) of '\(existing.fileName)' with '\(existing.name)' at line \(newLabel.scriptLine) of '\(newLabel.fileName)'", preset: "scripterror", fileName: fileName)
                }
                context.labels[label.lowercased()] = newLabel
            }
        }
    }

    func handleLine(_ line: ScriptLine) -> ScriptExecuteResult {
        guard let token = line.token else {
            sendText("Unknown script command: '\(line.originalText)'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .next
        }

        return executeToken(line, token)
    }

    func executeToken(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        lockQueue.sync {
            if let handler = tokenHandlers[token.description] {
                return handler(line, token)
            }

            sendText("No handler for script command: '\(line.originalText)'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .exit
        }
    }

    func gotoLabel(_ label: String, _ args: [String], _ isGosub: Bool = false) -> ScriptExecuteResult {
        let result = context.replaceVars(label)

        guard let currentLine = context.currentLine else {
            sendText("Tried to goto \(result) but had no 'currentLine'", preset: "scripterror", fileName: fileName)
            return .exit
        }

        guard let target = context.labels[result.lowercased()] else {
            sendText("label '\(result)' not found", preset: "scripterror", scriptLine: currentLine.lineNumber, fileName: currentLine.fileName)
            return .exit
        }

        delayedTask?.cancel()
        matchwait = nil
        matchStack.removeAll()

        context.setLabelVars(args)

        let command = isGosub ? "gosub" : "goto"

        notify("\(command) '\(result)'", debug: ScriptLogLevel.gosubs, scriptLine: currentLine.lineNumber, fileName: currentLine.fileName)

        let line = context.lines[target.line]
        let gosubContext = GosubContext(label: target, line: line, arguments: args, ifStack: context.ifStack, isGosub: isGosub)

        context.ifStack.clear()

        if isGosub {
            gosubContext.returnToLine = currentLine
            gosubContext.returnToIndex = context.currentLineNumber
            gosubStack.push(gosubContext)
        }

        context.currentLineNumber = target.line - 1

        return .next
    }

    func handleAction(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .action(name, action, pattern) = token else {
            return .next
        }

        let nameText = name.count > 0 ? " (\(name))" : ""
        let resolvedPattern = context.replaceVars(pattern)

        let message = "action\(nameText) \(action) \(resolvedPattern)"
        notify(message, debug: .actions, scriptLine: line.lineNumber, fileName: line.fileName)

        let actionOp = ActionOp(name: name, command: action, pattern: pattern, line: line)
        actions.append(actionOp)

        return .next
    }

    func handleActionToggle(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .actionToggle(name, toggle) = token else {
            return .next
        }

        let maybeToggle = context.replaceVars(toggle)
        let enabled = maybeToggle.trimmingCharacters(in: CharacterSet.whitespaces).lowercased() == "on"

        notify("action \(name) \(maybeToggle)", debug: .actions, scriptLine: line.lineNumber, fileName: line.fileName)

        if var action = actions.first(where: { $0.name == name }) {
            action.enabled = enabled
        }

        return .next
    }

    func handleLeftBrace(_: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .leftBrace = token else {
            return .next
        }

        // TODO: handle left brace - probably nothing?

        return .next
    }

    func handleRightBrace(_: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .rightBrace = token else {
            return .next
        }

        let (popped, ifLine) = context.popIfStack()
        guard popped else {
            let line = context.currentLine!
            sendText("End brace encountered without matching beginning block", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .exit
        }

        if ifLine?.ifResult == true {
            return .advanceToEndOfBlock
        }

        return .next
    }

    func handleComment(_: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .comment = token else {
            return .next
        }

        return .next
    }

    func handleDebug(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .debug(level) = token else {
            return .next
        }

        let targetLevel = context.replaceVars(level)

        debugLevel = ScriptLogLevel(rawValue: Int(targetLevel) ?? 0) ?? ScriptLogLevel.none
        notify("debug \(debugLevel.rawValue) (\(debugLevel))", debug: ScriptLogLevel.none, scriptLine: line.lineNumber)

        return .next
    }

    func handleEcho(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .echo(text) = token else {
            return .next
        }

        let targetText = context.replaceVars(text)
        notify("echo \(targetText)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        gameContext.events.echoText(targetText, preset: "scriptecho", mono: true)
        return .next
    }

    func handleElseIfSingle(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .elseIfSingle(exp, lineToken) = token else {
            return .next
        }

        guard context.ifStack.count > 0 else {
            sendText("Expected there to be a previous 'if' or 'else if'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .exit
        }

        context.pushCurrentLineToIfStack()

        var execute = false
        var result = false

        if context.ifStack.last2!.ifResult == false {
            execute = true
        } else {
            result = true
        }

        if execute {
            let res = funcEvaluator.evaluateBool(exp)
            result = res.result.toBool() == true

            if res.groups.count > 0 {
                context.setRegexVars(res.groups)
            }

            notify("else if: \(res.text) = \(result)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)
        } else {
            notify("else if: skipping", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)
        }

        line.ifResult = result

        if execute, result {
            return executeToken(line, lineToken)
        }

        return .next
    }

    func handleElseIf(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .elseIf(exp) = token else {
            return .next
        }

        guard context.ifStack.count > 0 else {
            sendText("Expected there to be a previous 'if' or 'else if'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .exit
        }

        context.pushCurrentLineToIfStack()

        var execute = false
        var result = false

        if context.ifStack.last2!.ifResult == false {
            execute = true
        } else {
            result = true
        }

        if execute {
            let res = funcEvaluator.evaluateBool(exp)
            result = res.result.toBool() == true

            if res.groups.count > 0 {
                context.setRegexVars(res.groups)
            }

            notify("else if: \(res.text) = \(result)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)
        } else {
            notify("else if: skipping", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)
        }

        line.ifResult = result

        if execute, result {
            return .next
        }

        return .advanceToNextBlock
    }

    func handleElseIfNeedsBrace(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .elseIfNeedsBrace(exp) = token else {
            return .next
        }

        guard context.ifStack.count > 0 else {
            sendText("Expected there to be a previous 'if' or 'else if'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .exit
        }

        if !context.consumeToken(.leftBrace) {
            sendText("Expecting opening bracket", preset: "scripterror", scriptLine: line.lineNumber + 1, fileName: line.fileName)
            return .exit
        }

        context.pushLineToIfStack(line)

        var execute = false
        var result = false

        if context.ifStack.last2!.ifResult == false {
            execute = true
        } else {
            result = true
        }

        if execute {
            let res = funcEvaluator.evaluateBool(exp)
            result = res.result.toBool() == true

            if res.groups.count > 0 {
                context.setRegexVars(res.groups)
            }

            notify("else if: \(res.text) = \(result)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)
        } else {
            notify("else if: skipping", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)
        }

        line.ifResult = result

        if execute, result {
            return .next
        }

        return .advanceToNextBlock
    }

    func handleElseSingle(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .elseSingle(lineToken) = token else {
            return .next
        }

        guard context.ifStack.count > 0 else {
            sendText("Expected there to be a previous 'if' or 'else if'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .exit
        }

        context.pushCurrentLineToIfStack()

        var execute = false

        if context.ifStack.last2!.ifResult == false {
            execute = true
        }

        notify("else: \(execute)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        if execute {
            return executeToken(line, lineToken)
        }

        return .next
    }

    func handleElse(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .else = token else {
            return .next
        }

        guard context.ifStack.count > 0 else {
            sendText("Expected there to be a previous 'if' or 'else if'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .exit
        }

        context.pushCurrentLineToIfStack()

        var execute = false

        if context.ifStack.last2!.ifResult == false {
            execute = true
        }

        notify("else: \(execute)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        if execute { return .next }
        return .advanceToNextBlock
    }

    func handleElseNeedsBrace(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .elseNeedsBrace = token else {
            return .next
        }

        guard context.ifStack.count > 0 else {
            sendText("Expected previous command to be an 'if' or 'else if'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .exit
        }

        if !context.consumeToken(.leftBrace) {
            sendText("Expecting opening bracket", preset: "scripterror", scriptLine: line.lineNumber + 1, fileName: line.fileName)
            return .exit
        }

        var execute = false

        if context.ifStack.last!.ifResult == false {
            execute = true
        }

        context.pushLineToIfStack(line)

        notify("else: \(execute)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        if execute { return .next }
        return .advanceToNextBlock
    }

    func handleEval(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .eval(variable, expression) = token else {
            return .next
        }

        let result = funcEvaluator.evaluateBool(expression)

        notify("eval \(result.text) = \(result.result)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        context.variables[variable] = result.result

        return .next
    }

    func handleExit(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .exit = token else {
            return .next
        }

        notify("exit", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        return .exit
    }

    func handleIfArgSingle(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .ifArgSingle(argCount, action) = token else {
            return .next
        }

        let hasArgs = context.args.count >= argCount
        line.ifResult = hasArgs
        context.pushCurrentLineToIfStack()

        notify("if_\(argCount) \(context.args.count) >= \(argCount) = \(hasArgs)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        if hasArgs {
            return executeToken(line, action)
        }

        return .next
    }

    func handleIfArg(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .ifArg(argCount) = token else {
            return .next
        }

        let hasArgs = context.args.count >= argCount
        line.ifResult = hasArgs
        context.pushCurrentLineToIfStack()

        notify("if_\(argCount) \(context.args.count) >= \(argCount) = \(hasArgs)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        if hasArgs {
            return .next
        }

        return .advanceToNextBlock
    }

    func handleIfArgNeedsBrace(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .ifArgNeedsBrace(argCount) = token else {
            return .next
        }

        let hasArgs = context.args.count >= argCount

        notify("if_\(argCount) \(context.args.count) >= \(argCount) = \(hasArgs)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber)

        if !context.consumeToken(.leftBrace) {
            sendText("Expected {", preset: "scripterror", scriptLine: line.lineNumber + 1, fileName: line.fileName)
            return .exit
        }

        line.ifResult = hasArgs
        context.pushLineToIfStack(line)

        if hasArgs {
            return .next
        }

        return .advanceToNextBlock
    }

    func handleIfSingle(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .ifSingle(expression, action) = token else {
            return .next
        }

        context.pushCurrentLineToIfStack()

        let execute = funcEvaluator.evaluateBool(expression)
        line.ifResult = execute.result.toBool() == true

        if execute.groups.count > 0 {
            context.setRegexVars(execute.groups)
        }

        notify("if \(execute.text) = \(execute.result)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        if line.ifResult == true {
            return executeToken(line, action)
        }

        return .next
    }

    func handleIf(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .if(expression) = token else {
            return .next
        }

        context.pushCurrentLineToIfStack()

        let execute = funcEvaluator.evaluateBool(expression)
        line.ifResult = execute.result.toBool() == true

        if execute.groups.count > 0 {
            context.setRegexVars(execute.groups)
        }

        notify("if \(execute.text) = \(execute.result)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        if line.ifResult == true {
            return .next
        }

        return .advanceToNextBlock
    }

    func handleIfNeedsBrace(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .ifNeedsBrace(expression) = token else {
            return .next
        }

        if !context.consumeToken(.leftBrace) {
            sendText("Expected {", preset: "scripterror", scriptLine: line.lineNumber + 1, fileName: line.fileName)
            return .exit
        }

        context.pushLineToIfStack(line)

        let execute = funcEvaluator.evaluateBool(expression)
        line.ifResult = execute.result.toBool() == true

        if execute.groups.count > 0 {
            context.setRegexVars(execute.groups)
        }

        notify("if \(execute.text) = \(execute.result)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        if line.ifResult == true {
            return .next
        }

        return .advanceToNextBlock
    }

    func handleGosub(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .gosub(label, args) = token else {
            return .next
        }

        guard gosubStack.count <= 100 else {
            sendText("Potential infinite loop of 100+ gosubs - use gosub clear if this is intended", preset: "scripterror", scriptLine: line.lineNumber, fileName: fileName)
            return .exit
        }

        let replacedLabel = context.replaceVars(label)

        if replacedLabel == "clear" {
            notify("gosub clear", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber, fileName: line.fileName)
            gosubStack.clear()
            return .next
        }

        let replaced = context.replaceVars(args)
        let arguments = [replaced] + replaced.argumentsSeperated()

        return gotoLabel(label, arguments, true)
    }

    func handleGoto(_: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .goto(label) = token else {
            return .next
        }

        return gotoLabel(label, [])
    }

    func handleLabel(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .label(label) = token else {
            return .next
        }

        notify("passing label '\(label)'", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber, fileName: line.fileName)
        return .next
    }

    func handleMatch(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .match(label, value) = token else {
            return .next
        }

        matchStack.append(MatchMessage(label, value, line.lineNumber))
        return .next
    }

    func handleMatchre(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .matchre(label, value) = token else {
            return .next
        }

        matchStack.append(MatchreMessage(label, value, line.lineNumber))
        return .next
    }

    func handleMatchwait(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .matchwait(str) = token else {
            return .next
        }

        let maybeNumber = context.replaceVars(str)
        let timeout = Double(maybeNumber) ?? -1

        let time = timeout > 0 ? "\(timeout)" : ""
        notify("matchwait \(time)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber)

        let token = Matchwait()
        matchwait = token

        if timeout > 0 {
            delayedTask = delay(timeout, queue: lockQueue) {
                if let match = self.matchwait, match.id == token.id {
                    self.matchwait = nil
                    self.matchStack.removeAll()
                    self.notify("matchwait timeout", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)
                    self.next()
                }
            }
        }

        return .wait
    }

    func handleMath(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .math(variable, function, number) = token else {
            return .next
        }

        let existingVariable = context.replaceVars(context.variables[variable] ?? "0")

        guard let existingValue = Double(existingVariable) else {
            sendText("unable to convert '\(existingVariable)' to a number", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .next
        }

        guard let numberValue = Double(number) else {
            sendText("unable to convert '\(number)' to a number", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .next
        }

        var result: Double = 0

        switch function.lowercased() {
        case "set":
            result = numberValue

        case "add":
            result = existingValue + numberValue

        case "subtract":
            result = existingValue - numberValue

        case "multiply":
            result = existingValue * numberValue

        case "divide":
            guard numberValue != 0 else {
                sendText("cannot divide by zero!", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
                return .next
            }

            result = existingValue / numberValue

        default:
            sendText("unknown math function '\(function)'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .next
        }

        var textResult = "\(result)"

        if result == rint(result) {
            textResult = "\(Int(result))"
        }

        context.variables[variable] = textResult

        notify("math \(variable): \(existingValue) \(function) \(numberValue) = \(textResult)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        return .next
    }

    func handleMove(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .move(text) = token else {
            return .next
        }

        let send = context.replaceVars(text)

        notify("move \(send)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        reactToStream.append(MoveOp())

        let command = Command2(command: send, fileName: fileName, preset: "scriptinput")
        gameContext.events.sendCommand(command)

        return .wait
    }

    func handleNextroom(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .nextroom = token else {
            return .next
        }

        notify("nextroom", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        reactToStream.append(NextRoomOp())

        return .wait
    }

    func handlePause(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .pause(str) = token else {
            return .next
        }

        let maybeNumber = context.replaceVars(str)
        let duration = Double(maybeNumber) ?? 1

        notify("pausing for \(duration) seconds", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        delayedTask = delay(duration, queue: lockQueue) {
            self.next()
        }

        return .wait
    }

    func handlePut(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .put(text) = token else {
            return .next
        }

        let send = context.replaceVars(text)

        notify("put \(send)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        let command = Command2(command: send, fileName: fileName)
        gameContext.events.sendCommand(command)

        return .next
    }

    func handleRandom(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .random(minStr, maxStr) = token else {
            return .next
        }

        let min = context.replaceVars(minStr)
        let max = context.replaceVars(maxStr)

        guard let minN = Int(min), let maxN = Int(max) else {
            return .next
        }

        let diceRoll = Int.random(in: minN ... maxN)

        context.variables["r"] = "\(diceRoll)"

        notify("random \(minN), \(maxN) = \(diceRoll)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        return .next
    }

    func handleReturn(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .return = token else {
            return .next
        }

        guard let ctx = gosubStack.pop(), let returnToLine = ctx.returnToLine, let returnToIndex = ctx.returnToIndex else {
            notify("no gosub to return to!", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber)
            sendText("no gosub to return to!", preset: "scripterror", scriptLine: line.lineNumber, fileName: fileName)
            return .exit
        }

        if let prev = gosubStack.last {
            context.setLabelVars(prev.arguments)
        } else {
            context.setLabelVars([])
        }

        context.ifStack = ctx.ifStack

        notify("returning to line \(returnToLine.lineNumber)", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber, fileName: line.fileName)

        context.currentLineNumber = returnToIndex

        return .next
    }

    func handleSave(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .save(value) = token else {
            return .next
        }

        let result = context.replaceVars(value)
        context.variables["s"] = result

        notify("save \(result)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        return .next
    }

    func handleSend(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .send(text) = token else {
            return .next
        }

        let result = context.replaceVars(text)

        notify("send \(result)", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber, fileName: line.fileName)

        let command = Command2(command: "#send \(result)", fileName: fileName, preset: "scriptinput")
        gameContext.events.sendCommand(command)

        return .next
    }

    func handleShift(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .shift = token else {
            return .next
        }

        notify("shift", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        context.shiftArgs()

        return .next
    }

    func handleUnVar(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .unvar(variable) = token else {
            return .next
        }

        let varName = context.replaceVars(variable)

        context.variables.removeValue(forKey: varName)

        notify("unvar \(varName)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        return .next
    }

    func handleVariable(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .variable(variable, value) = token else {
            return .next
        }

        let varName = context.replaceVars(variable)
        let varValue = context.replaceVars(value)

        context.variables[varName] = varValue

        notify("var \(varName) \(varValue)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        return .next
    }

    func handleWaitEval(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitEval(text) = token else {
            return .next
        }

        notify("waiteval \(text)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        reactToStream.append(WaitEvalOp(text))

        return .wait
    }

    func handleWaitforPrompt(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitforPrompt(text) = token else {
            return .next
        }

        notify("wait \(text)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        reactToStream.append(WaitforPromptOp())

        return .wait
    }

    func handleWaitfor(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitfor(text) = token else {
            return .next
        }

        notify("waitfor \(text)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        reactToStream.append(WaitforOp(text))

        return .wait
    }

    func handleWaitforRe(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitforre(pattern) = token else {
            return .next
        }

        notify("waitforre \(pattern)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        reactToStream.append(WaitforReOp(pattern))

        return .wait
    }
}
