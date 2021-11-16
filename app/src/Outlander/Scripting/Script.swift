//
//  Script.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

func delay(_ delay: Double, _ closure: @escaping () -> Void) -> DispatchWorkItem {
    let task = DispatchWorkItem { closure() }
    // TODO: swap from main queue
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
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
    var fileName: String
}

class ScriptContext {
    private var context: GameContext

    var lines: [ScriptLine] = []
    var labels: [String: Label] = [:]
    var variables: [String: String] = [:]
    var args: [String] = []
    var argumentVars: [String: String] = [:]
    var actionVars: [String: String] = [:]
    var labelVars: [String: String] = [:]
    var regexVars: [String: String] = [:]
    var currentLineNumber: Int = -1

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

    init(context: GameContext) {
        self.context = context
    }

    func advance() {
        currentLineNumber += 1
    }

    func retreat() {
        currentLineNumber -= 1
    }

    func replaceVars(_ input: String) -> String {
        let context = VariableContext()
        context.add("$", sortedKeys: regexVars.keys.sorted { $0.count > $1.count }, values: { key in self.regexVars[key] })
        context.add("$", sortedKeys: labelVars.keys.sorted { $0.count > $1.count }, values: { key in self.labelVars[key] })
        context.add("%", sortedKeys: variables.keys.sorted { $0.count > $1.count }, values: { key in self.variables[key] })
        context.add("%", sortedKeys: argumentVars.keys.sorted { $0.count > $1.count }, values: { key in self.argumentVars[key] })
        context.add("$", sortedKeys: self.context.globalVars.keys(), values: { key in self.context.globalVars[key] })
        return VariableReplacer().replace(input, context: context)
    }

    func replaceActionVars(_ input: String) -> String {
        let context = VariableContext()
        context.add("$", sortedKeys: actionVars.keys.sorted { $0.count > $1.count }, values: { key in self.actionVars[key] })
        context.add("%", sortedKeys: variables.keys.sorted { $0.count > $1.count }, values: { key in self.variables[key] })
        context.add("%", sortedKeys: argumentVars.keys.sorted { $0.count > $1.count }, values: { key in self.argumentVars[key] })
        context.add("$", sortedKeys: self.context.globalVars.keys(), values: { key in self.context.globalVars[key] })
        return VariableReplacer().replace(input, context: context)
    }

    func setRegexVars(_ vars: [String]) {
        regexVars = [:]
        for (index, param) in vars.enumerated() {
            regexVars["\(index)"] = param
        }
    }

    func setActionVars(_ vars: [String]) {
        actionVars = [:]
        for (index, param) in vars.enumerated() {
            actionVars["\(index)"] = param
        }
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

        return fileString.components(separatedBy: .newlines)
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

class Script {
    var started: Date?
    var fileName: String = ""
    var debugLevel = ScriptLogLevel.none

    private var stackTrace: Stack<ScriptLine>
    private var tokenHandlers: [String: (ScriptLine, ScriptTokenValue) -> ScriptExecuteResult]
    private var reactToStream: [IWantStreamInfo] = []
    private var matchStack: [IMatch] = []
    private var matchwait: Matchwait?
    private var actions: [IAction] = []

    var stopped = false
    var paused = false
    var nextAfterUnpause = false

    var tokenizer: ScriptTokenizer
    var loader: IScriptLoader
    var context: ScriptContext
    var gameContext: GameContext

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

        includeRegex = RegexFactory.get("^\\s*include (.+)$")!
        labelRegex = RegexFactory.get("^\\s*(\\w+((\\.|-|\\w)+)?):")!

        context = ScriptContext(context: gameContext)
        tokenHandlers = [:]
        tokenHandlers["action"] = handleAction
        tokenHandlers["actiontoggle"] = handleActionToggle
        tokenHandlers["comment"] = handleComment
        tokenHandlers["debug"] = handleDebug
        tokenHandlers["echo"] = handleEcho
        tokenHandlers["exit"] = handleExit
        tokenHandlers["goto"] = handleGoto
        tokenHandlers["label"] = handleLabel
        tokenHandlers["match"] = handleMatch
        tokenHandlers["matchre"] = handleMatchre
        tokenHandlers["matchwait"] = handleMatchwait
        tokenHandlers["move"] = handleMove
        tokenHandlers["nextroom"] = handleNextroom
        tokenHandlers["pause"] = handlePause
        tokenHandlers["put"] = handlePut
        tokenHandlers["random"] = handleRandom
        tokenHandlers["save"] = handleSave
        tokenHandlers["send"] = handleSend
        tokenHandlers["variable"] = handleVariable
        tokenHandlers["wait"] = handleWaitforPrompt
        tokenHandlers["waitfor"] = handleWaitfor
        tokenHandlers["waitforre"] = handleWaitforRe

        Script.dateFormatter.dateFormat = "hh:mm a"
    }

    deinit {
        self.gameContext.events.unregister(self)
    }

    func run(_: [String]) {
        started = Date()

        let formattedDate = Script.dateFormatter.string(from: started!)

        sendText("[Starting '\(fileName)' at \(formattedDate)]")

        initialize(fileName)

        next()
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
        case .wait:
            print("waiting")
            return
        case .exit: cancel()
        case .advanceToNextBlock: cancel()
        case .advanceToEndOfBlock: cancel()
        }
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
        case .next: next()
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
                if let existing = context.labels[label] {
                    sendText("replacing label '\(existing.name)' from '\(existing.fileName)'", preset: "scripterror", scriptLine: index)
                }
                context.labels[label.lowercased()] = Label(name: label.lowercased(), line: context.lines.count - 1, fileName: fileName)
            }
        }
    }

    func handleLine(_ line: ScriptLine) -> ScriptExecuteResult {
        guard let token = line.token else {
            sendText("Unknown script command: '\(line.originalText)'", preset: "scripterror", scriptLine: line.lineNumber, fileName: fileName)
            return .next
        }

        return executeToken(line, token)
    }

    func executeToken(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        if let handler = tokenHandlers[token.description] {
            return handler(line, token)
        }

        sendText("No handler for script command: '\(line.originalText)'", preset: "scripterror", scriptLine: line.lineNumber, fileName: fileName)
        return .exit
    }

    func gotoLabel(_ label: String, _: [String], _ isGosub: Bool = false) -> ScriptExecuteResult {
        let result = context.replaceVars(label)

        guard let currentLine = context.currentLine else {
            sendText("Tried to goto \(result) but had no 'currentLine'", preset: "scripterror", fileName: fileName)
            return .exit
        }

        guard let target = context.labels[result.lowercased()] else {
            sendText("label '\(result)' not found", preset: "scripterror", scriptLine: currentLine.lineNumber, fileName: fileName)
            return .exit
        }

        delayedTask?.cancel()
        matchwait = nil
        matchStack.removeAll()

        let command = isGosub ? "gosub" : "goto"

        notify("\(command) '\(result)'", debug: ScriptLogLevel.gosubs, scriptLine: currentLine.lineNumber)

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
        notify(message, debug: .actions, scriptLine: line.lineNumber)

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

        notify("action \(name) \(maybeToggle)", debug: .actions, scriptLine: line.lineNumber)

        if var action = actions.first(where: { $0.name == name }) {
            action.enabled = enabled
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
        notify("echo \(targetText)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber)

        gameContext.events.echoText(targetText, preset: "scriptecho")
        return .next
    }

    func handleExit(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .exit = token else {
            return .next
        }

        notify("exit", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber)

        return .exit
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

        notify("passing label '\(label)'", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber)
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

        matchStack.append(MatchMessage(label, value, line.lineNumber))
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
            delayedTask = delay(timeout) {
                if let match = self.matchwait, match.id == token.id {
                    self.matchwait = nil
                    self.matchStack.removeAll()
                    self.notify("matchwait timeout", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber)
                    self.next()
                }
            }
        }

        return .wait
    }

    func handleMove(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .move(text) = token else {
            return .next
        }

        let send = context.replaceVars(text)

        notify("move \(send)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber)

        reactToStream.append(MoveOp())

        let command = Command2(command: send)
        gameContext.events.sendCommand(command)

        return .wait
    }

    func handleNextroom(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .nextroom = token else {
            return .next
        }

        notify("nextroom", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber)

        reactToStream.append(NextRoomOp())

        return .wait
    }

    func handlePause(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .pause(str) = token else {
            return .next
        }

        let maybeNumber = context.replaceVars(str)
        let duration = Double(maybeNumber) ?? 1

        notify("pausing for \(duration) seconds", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber)

        delayedTask = delay(duration) {
            self.next()
        }

        return .wait
    }

    func handlePut(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .put(text) = token else {
            return .next
        }

        let send = context.replaceVars(text)

        notify("put \(send)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber)

        let command = Command2(command: send)
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

        notify("random \(minN), \(maxN) = \(diceRoll)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber)

        return .next
    }

    func handleSave(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .save(value) = token else {
            return .next
        }

        let result = context.replaceVars(value)
        context.variables["s"] = result

        notify("save \(result)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber)

        return .next
    }

    func handleSend(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .send(text) = token else {
            return .next
        }

        let result = context.replaceVars(text)

        notify("#send \(result)", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber)

        let command = Command2(command: "#send \(result)")
        gameContext.events.sendCommand(command)

        return .next
    }

    func handleVariable(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .variable(variable, value) = token else {
            return .next
        }

        let varName = context.replaceVars(variable)
        let varValue = context.replaceVars(value)

        context.variables[varName] = varValue

        notify("var \(varName) \(varValue)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber)

        return .next
    }

    func handleWaitforPrompt(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitforPrompt(text) = token else {
            return .next
        }

        notify("wait \(text)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber)

        reactToStream.append(WaitforOp(text))

        return .wait
    }

    func handleWaitfor(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitfor(text) = token else {
            return .next
        }

        notify("waitfor \(text)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber)

        reactToStream.append(WaitforOp(text))

        return .wait
    }

    func handleWaitforRe(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitforre(pattern) = token else {
            return .next
        }

        notify("waitforre \(pattern)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber)

        reactToStream.append(WaitforReOp(pattern))

        return .wait
    }
}
