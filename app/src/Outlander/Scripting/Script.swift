//
//  Script.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

func delay(_ delay: Double, _ closure: @escaping () -> ()) -> DispatchWorkItem {
    let task = DispatchWorkItem { closure() }
    // TODO: swap from main queue
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    return task
}

public enum ScriptLogLevel : Int {
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
    var lines: [ScriptLine] = []
    var labels: [String: Label] = [:]

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

    func advance() {
        currentLineNumber += 1
    }

    func retreat() {
        currentLineNumber -= 1
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
    func load(_ fileName: String) -> [String]
}

class InMemoryScriptLoader: IScriptLoader {
    var lines: [String: [String]] = [:]

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
    func stream(_ text: String, _ context: ScriptContext) -> CheckStreamResult
    func execute(_ script:Script, _ context:ScriptContext)
}

class Script {
    var started: Date?
    var fileName: String = ""
    var debugLevel:ScriptLogLevel = ScriptLogLevel.none

    private var stackTrace: Stack<ScriptLine>
    private var tokenHandlers: [String: (ScriptLine, ScriptTokenValue) -> ScriptExecuteResult]
    private var reactToStream: [IWantStreamInfo] = []
    private var matchStack: [IMatch] = []
    private var matchwait: Matchwait?

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

        context = ScriptContext()
        tokenHandlers = [:]
        tokenHandlers["comment"] = self.handleComment
        tokenHandlers["debug"] = self.handleDebug
        tokenHandlers["echo"] = self.handleEcho
        tokenHandlers["exit"] = self.handleExit
        tokenHandlers["goto"] = self.handleGoto
        tokenHandlers["label"] = self.handleLabel
        tokenHandlers["match"] = self.handleMatch
        tokenHandlers["matchre"] = self.handleMatchre
        tokenHandlers["matchwait"] = self.handleMatchwait
        tokenHandlers["pause"] = self.handlePause
        tokenHandlers["put"] = self.handlePut
        tokenHandlers["waitfor"] = self.handleWaitfor
        tokenHandlers["waitforre"] = self.handleWaitforRe

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
        sendText("[Script '\(fileName)' completed after \(diff.stringTime)]")

        self.gameContext.events.unregister(self)
        self.gameContext.events.post("ol:script:complete", data: fileName)
    }

    func stream(_ text: String) {
        guard text.count > 0, !paused, !stopped else {
            return
        }

        let handlers = self.reactToStream.filter { x in
            let res = x.stream(text, self.context)
            switch res {
            case .match(let txt):
                notify("matched \(txt)", debug: .wait)
                return true
            default:
                return false
            }
        }

        handlers.forEach { handler in
            guard let idx = reactToStream.firstIndex(where: { $0.id == handler.id  }) else {
                return
            }
            reactToStream.remove(at: idx)
            handler.execute(self, context)
        }

        checkMatches(text)
    }

    private func checkMatches(_ text:String) {
        guard let _ = self.matchwait else {
            return
        }

        var foundMatch: IMatch? = nil

        for match in self.matchStack {
            if match.isMatch(text) {
                foundMatch = match
                break
            }
        }

        guard let match = foundMatch else {
            return
        }

        self.matchwait = nil
        self.matchStack.removeAll()

        // TODO: resolve variables
//        let label = self.context.simplify(match.label)
        let label = match.label

        self.notify("match \(label)", debug:ScriptLogLevel.wait, scriptLine: match.lineNumber)
        let result = self.gotoLabel(label, match.groups)

        switch result {
        case .exit: self.cancel()
        case .next: self.next()
        default: return
        }
    }

    private func sendText(_ text: String, preset: String = "scriptinput", scriptLine: Int = -1, fileName: String = "") {
        guard fileName.count > 0 else {
            self.gameContext.events.echoText("\(text)", preset: preset, mono: true)
            return
        }

        let name = fileName == "" ? self.fileName : fileName
        let display = scriptLine > -1 ? "[\(name)(\(scriptLine))]: \(text)" : "[\(name)]: \(text)"

        self.gameContext.events.echoText(display, preset: preset, mono: true)
    }
    
    private func notify(_ text: String, debug: ScriptLogLevel, preset: String = "scriptinfo", scriptLine: Int = -1, fileName: String = "") {
        guard debugLevel.rawValue > debug.rawValue else {
            return
        }

        let name = fileName == "" ? self.fileName : fileName

        let display = scriptLine > -1 ? "[\(name)(\(scriptLine))]: \(text)" : "[\(name)]: \(text)"
        
        self.gameContext.events.echoText(display, preset: preset)
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

    func gotoLabel(_ label: String, _ params: [String], _ isGosub: Bool = false) -> ScriptExecuteResult {
        // TODO: resolve variables
        let result = label

        guard let currentLine = self.context.currentLine else {
            self.sendText("Tried to goto \(result) but had no 'currentLine'", preset:"scripterror", fileName: self.fileName)
            return .exit
        }

        guard let target = self.context.labels[result.lowercased()] else {
            self.sendText("label '\(result)' not found", preset: "scripterror", scriptLine: currentLine.lineNumber, fileName: self.fileName)
            return .exit
        }

        self.delayedTask?.cancel()
//        self.matchwait = nil
//        self.matchStack.removeAll()
        
        let command = isGosub ? "gosub" : "goto"

        self.notify("\(command) '\(result)'", debug:ScriptLogLevel.gosubs, scriptLine: currentLine.lineNumber)

//        let currentLineNumber = self.context.currentLineNumber
        self.context.currentLineNumber = target.line - 1

        return .next
    }

    func handleComment(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .comment(_) = token else {
            return .next
        }

        return .next
    }

    func handleDebug(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .debug(level) = token else {
            return .next
        }

        // TODO resolve variables

        self.debugLevel = ScriptLogLevel(rawValue: Int(level) ?? 0) ?? ScriptLogLevel.none
        self.notify("debug \(self.debugLevel.rawValue) (\(self.debugLevel))", debug:ScriptLogLevel.none, scriptLine: line.lineNumber)
        
        return .next
    }

    func handleEcho(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .echo(text) = token else {
            return .next
        }

        // TODO: resolve variables

        self.notify("echo \(text)", debug:ScriptLogLevel.vars, scriptLine: line.lineNumber)

        gameContext.events.echoText(text, preset: "scriptecho")
        return .next
    }
    
    func handleExit(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .exit = token else {
            return .next
        }

        self.notify("exit", debug:ScriptLogLevel.vars, scriptLine: line.lineNumber)

        return .exit
    }

    func handleGoto(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .goto(label) = token else {
            return .next
        }

        return gotoLabel(label, [])
    }

    func handleLabel(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .label(label) = token else {
            return .next
        }

        self.notify("passing label '\(label)'", debug:ScriptLogLevel.gosubs, scriptLine: line.lineNumber)
        return .next
    }

    func handleMatch(_ line:ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .match(label, value) = token else {
            return .next
        }

        self.matchStack.append(MatchMessage(label, value, line.lineNumber))
        return .next
    }

    func handleMatchre(_ line:ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .matchre(label, value) = token else {
            return .next
        }

        self.matchStack.append(MatchMessage(label, value, line.lineNumber))
        return .next
    }

    func handleMatchwait(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .matchwait(str) = token else {
            return .next
        }

        let timeout: Double = Double(str) ?? -1

        let time = timeout > 0 ? "\(timeout)" : ""
        self.notify("matchwait \(time)", debug:ScriptLogLevel.wait, scriptLine: line.lineNumber)

        let token = Matchwait()
        self.matchwait = token

        if timeout > 0 {
            self.delayedTask = delay(timeout) {
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
    
    func handlePause(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .pause(maybeNumber) = token else {
            return .next
        }

        // TODO: resolve variables

        let duration = Double(maybeNumber) ?? 1

        self.notify("pausing for \(duration) seconds", debug:ScriptLogLevel.wait, scriptLine: line.lineNumber)

        self.delayedTask = delay(duration) {
            self.next()
        }

        return .wait
    }

    func handlePut(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .put(text) = token else {
            return .next
        }

        // TODO: resolve variables

        self.notify("put \(text)", debug:ScriptLogLevel.vars, scriptLine: line.lineNumber)

        let command = Command2(command: text)
        gameContext.events.sendCommand(command)

        return .next
    }

    func handleWaitfor(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitfor(text) = token else {
            return .next
        }

        // TODO: resolve variables

        self.notify("waitfor \(text)", debug:ScriptLogLevel.wait, scriptLine: line.lineNumber)

        self.reactToStream.append(WaitforOp(text))

        return .wait
    }
    
    func handleWaitforRe(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitforre(pattern) = token else {
            return .next
        }

        // TODO: resolve variables

        self.notify("waitforre \(pattern)", debug:ScriptLogLevel.wait, scriptLine: line.lineNumber)

        self.reactToStream.append(WaitforReOp(pattern))

        return .wait
    }
}
