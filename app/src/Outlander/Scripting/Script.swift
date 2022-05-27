//
//  Script.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

@discardableResult func delay(_ delay: Double, queue: DispatchQueue = DispatchQueue.global(qos: .userInteractive), _ closure: @escaping () -> Void) -> DispatchWorkItem {
    let task = DispatchWorkItem { closure() }
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

extension Label: CustomStringConvertible {
    var description: String {
        "\(line) \(fileName) (\(scriptLine)) \(name)"
    }
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

extension ScriptLine: CustomStringConvertible {
    var description: String {
        "[\(fileName)(\(lineNumber))]: \(originalText)"
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
    var className: String { get set }
    var enabled: Bool { get set }
    var line: ScriptLine { get set }
}

enum ScriptQueueItem {
    case next
    case stream(String, [StreamCommand])
}

extension ScriptQueueItem: CustomStringConvertible {
    var description: String {
        switch self {
        case .next:
            return "next"
        case .stream:
            return "stream"
        }
    }
}

@propertyWrapper
struct Atomic<Value> {
    private let lock = NSLock()
    private var value: Value

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            value = newValue
        }
    }
}

class Script {
    private let lockQueue = AtomicQueue(label: "com.outlanderapp.script.\(UUID().uuidString)", qos: .userInteractive, autoreleaseFrequency: .never)
    private let log = LogManager.getLog("Script")

    var async = true {
        didSet {
            lockQueue.enabled = async
        }
    }

    var started: Date?
    var fileName: String = ""
    var debugLevel = ScriptLogLevel.none

    private var scriptQueue = Queue<ScriptQueueItem>()
    private var stackTrace: Stack<ScriptLine>
    private var tokenHandlers: [String: (ScriptLine, ScriptTokenValue) -> ScriptExecuteResult]
    private var reactToStream = AtomicArray<IWantStreamInfo>()
    private var actions: [IAction] = []

    private var gosubStack: Stack<GosubContext>

    private var matchStack = AtomicArray<IMatch>()
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

    var delayedTask = DelayedTask()

    var lastNext = Date()
    var lastNextCount: Int = 0

    static var dateFormatter = DateFormatter()

    init(_ fileName: String, loader: IScriptLoader, gameContext: GameContext) throws {
        self.fileName = fileName
        self.loader = loader
        self.gameContext = gameContext

        tokenizer = ScriptTokenizer()

        stackTrace = Stack<ScriptLine>(50)
        gosubStack = Stack<GosubContext>(101)

        includeRegex = RegexFactory.get("^\\s*include (.+)$")!
        labelRegex = RegexFactory.get("^\\s*(\\w+((\\.|-|\\w)+)?):")!

        context = ScriptContext(context: gameContext)
        context.variables["scriptname"] = fileName
        funcEvaluator = FunctionEvaluator(gameContext, context.replaceVars)

        tokenHandlers = [:]
        tokenHandlers["action"] = handleAction
        tokenHandlers["actioneval"] = handleActionEval
        tokenHandlers["actiontoggle"] = handleActionToggle
        tokenHandlers["leftbrace"] = handleLeftBrace
        tokenHandlers["rightbrace"] = handleRightBrace
        tokenHandlers["comment"] = handleComment
        tokenHandlers["counter"] = handleCounter
        tokenHandlers["debug"] = handleDebug
        tokenHandlers["delay"] = handleDelay
        tokenHandlers["echo"] = handleEcho
        tokenHandlers["eval"] = handleEval
        tokenHandlers["evalmath"] = handleEvalMath
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
        tokenHandlers["printbox"] = handlePrintBox
        tokenHandlers["random"] = handleRandom
        tokenHandlers["return"] = handleReturn
        tokenHandlers["save"] = handleSave
        tokenHandlers["send"] = handleSend
        tokenHandlers["shift"] = handleShift
        tokenHandlers["timer"] = handleTimer
        tokenHandlers["unvar"] = handleUnVar
        tokenHandlers["variable"] = handleVariable
        tokenHandlers["waiteval"] = handleWaitEval
        tokenHandlers["wait"] = handleWaitforPrompt
        tokenHandlers["waitfor"] = handleWaitfor
        tokenHandlers["waitforre"] = handleWaitforRe

        Script.dateFormatter.dateFormat = "hh:mm a"
    }

    func run(_ args: [String]) {
        func doRun() {
            started = Date()

            context.setArgumentVars(args)

            initialize(fileName, isInclude: false)

//            for label in self.context.labels.sorted(by: { $0.value.line < $1.value.line }) {
//                print(label.value.description)
//            }
//
//            for (idx, line) in self.context.lines.enumerated() {
//                print("\(idx) \(line.description)")
//            }

            queueNext()
        }

        lockQueue.async {
            doRun()
        }
    }

    func handleError() -> ScriptExecuteResult {
        guard context.labels["scripterror"] != nil else {
            return .exit
        }

        _ = gotoLabel("scripterror", [""])
        return .next
    }

    func gosubClear() {
        gosubStack.clear()
    }

    func queueNext() {
        scriptQueue.queue(.next)
        next()
    }

    func next() {
        lockQueue.async {
            self._next()
        }
    }

    @Atomic() private var inLoop = false
    private func _next() {
        guard !inLoop, !stopped else { return }

        if paused {
            nextAfterUnpause = true
            return
        }

        inLoop = true
        while !stopped, !paused, let queueItem = scriptQueue.dequeue() {
            switch queueItem {
            case let .stream(text, tokens):
                _stream(text, tokens)
                continue
            case .next:
                _processLine()
            }
        }
        inLoop = false
        if paused {
            nextAfterUnpause = true
        }
    }

    private func _processLine() {
        let interval = Date().timeIntervalSince(lastNext)

        if interval < 0.1 {
            lastNextCount += 1
        } else {
            lastNextCount = 0
        }

        guard lastNextCount <= 1000 else {
            printStacktrace()
            sendText("Possible infinite loop detected. Please review the above stack trace and check the commands you are sending for an infinite loop.", preset: "scripterror", fileName: fileName)
            cancel()
            return
        }

        lastNext = Date()

        context.advance()

        guard let line = context.currentLine else {
            cancel()
            return
        }

        if line.token == nil {
            line.token = tokenizer.read(line.originalText)
        }

        stackTrace.push(line)

//        log.info("passing \(line.lineNumber) - \(line.originalText)")

        let result = handleLine(line)

        switch result {
        case .next: scriptQueue.queue(.next)
        case .wait: return
        case .exit: cancel()
        case .advanceToNextBlock:
            if context.advanceToNextBlock() {
                scriptQueue.queue(.next)
            } else {
                if let line = context.currentLine {
                    sendText("Unable to match next if block", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
                }
                cancel()
            }
        case .advanceToEndOfBlock:
            if context.advanceToEndOfBlock() {
                scriptQueue.queue(.next)
            } else {
                if let line = context.currentLine {
                    sendText("Unable to match end of block", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
                }
                cancel()
            }
        }
    }

    func nextAfterRoundtime() {
        _nextAfterRoundtime()
    }

    func _nextAfterRoundtime() {
        let ignoreRoundtime = gameContext.globalVars["scriptengine:ignoreroundtime"]?.toBool()

        if ignoreRoundtime == true {
            queueNext()
            return
        }

        if let roundtime = context.roundtime, roundtime > 0 {
            delayedTask.set(roundtime, queue: lockQueue.queue) {
                self.nextAfterRoundtime()
            }
            return
        }

        queueNext()
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

        scriptQueue.clear()

        paused = false

        if nextAfterUnpause {
            queueNext()
        }
    }

    func cancel() {
        stop()
    }

    func matchesName(_ name: String) -> Bool {
        var nameToCheck = fileName
        // trim off any leading folder name
        if let idx = fileName.lastIndex(of: "/") {
            nameToCheck = String(fileName[fileName.index(after: idx)...])
        }
        return nameToCheck == name
    }

    private func stop() {
        delayedTask.reset()
        matchwait = nil
        matchStack.removeAll()

        if stopped { return }

        stopped = true
        context.currentLineNumber = -1

        let diff = Date().timeIntervalSince(started!)
        sendText("[Script '\(fileName)' completed after \(diff.formatted)]")

        gameContext.events2.post(ScriptCompleteEvent(name: fileName))
    }

    func setLogLevel(_ level: ScriptLogLevel) {
        debugLevel = level
        sendText("[Script '\(fileName)' - setting debug level to \(level.rawValue)]")
    }

    func printStacktrace() {
        sendText("+----- Tracing last \(stackTrace.count) commands for'\(fileName)' ----------+", preset: "scriptinfo")
        for line in stackTrace.all {
            sendText("[\(line.fileName)(\(line.lineNumber)]: \(line.originalText)", preset: "scriptinfo")
        }
        sendText("+---------------------------------------------------------+", preset: "scriptinfo")
    }

    func printVars() {
        let diff = Date().timeIntervalSince(started!)
        sendText("+------- '\(fileName)' variables (running for \(diff.formatted) -------+", preset: "scriptinfo")
        for v in varsForDisplay() {
            sendText("|  \(v)", preset: "scriptinfo")
        }
        sendText("+---------------------------------------------------------+", preset: "scriptinfo")
    }

    func varsForDisplay() -> [String] {
        var vars: [String] = []

        for key in context.argumentVars.displayKeys {
            vars.append("\(key): \(context.argumentVars[key] ?? "")")
        }

        for key in context.variables.displayKeys {
            vars.append("\(key): \(context.variables[key] ?? "")")
        }

        return vars
    }

    func stream(_ text: String, _ tokens: [StreamCommand]) {
        guard !paused, !stopped, text.count > 0 || tokens.count > 0 else {
            return
        }

        scriptQueue.queue(.stream(text, tokens))
        next()
    }

    private func _stream(_ text: String, _ tokens: [StreamCommand]) {
        _ = checkActions(text, tokens)

        let handlers = reactToStream.filter { x in
            let res = x.stream(text, tokens, self.context)
            switch res {
            case let .match(txt):
                self.notify("matched \(txt)", debug: .wait)
                return true
            default:
                return false
            }
        }

        handlers.forEach { handler in
            guard let idx = self.reactToStream.firstIndex(where: { $0.id == handler.id }) else {
                return
            }
            self.reactToStream.remove(at: idx)
            handler.execute(self, self.context)
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
                notify(txt, debug: .actions, scriptLine: a.line.lineNumber, fileName: a.line.fileName)
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
        guard !text.isEmpty else {
            return
        }

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
        case .next: scriptQueue.queue(.next)
        default: return
        }
    }

    private func sendText(_ text: String, preset: String = "scriptinput", scriptLine: Int = -1, fileName: String = "") {
        guard fileName.count > 0 else {
            gameContext.events2.echoText("\(text)", preset: preset, mono: true)
            return
        }

        let name = fileName == "" ? self.fileName : fileName
        let display = scriptLine > -1 ? "[\(name)(\(scriptLine))]: \(text)" : "[\(name)]: \(text)"

        gameContext.events2.echoText(display, preset: preset, mono: true)
    }

    private func notify(_ text: String, debug: ScriptLogLevel, preset: String = "scriptinfo", scriptLine: Int = -1, fileName: String = "") {
        guard debugLevel.rawValue >= debug.rawValue else {
            return
        }

        let name = fileName == "" ? self.fileName : fileName

        let display = scriptLine > -1 ? "[\(name)(\(scriptLine))]: \(text)" : "[\(name)]: \(text)"

        gameContext.events2.echoText(display, preset: preset)
    }

    private func initialize(_ fileName: String, isInclude: Bool) {
        let scriptFile = loader.load(fileName, echo: false)

        guard let scriptFileName = scriptFile.file, scriptFile.lines.count > 0 else {
            sendText("Script '\(fileName)' is empty or does not exist", preset: "scripterror")
            return
        }

        let scriptName = scriptFileName.absoluteString.contains("file:///")
            ? scriptFileName
            .absoluteString[7...]
            .replacingOccurrences(of: gameContext.applicationSettings.paths.scripts.absoluteString[7...], with: "")
            .replacingOccurrences(of: ".cmd", with: "").hexDecoededString()
            : scriptFileName.absoluteString.hexDecoededString()

        if !isInclude {
            let formattedDate = Script.dateFormatter.string(from: started!)

            var scriptFilePath = scriptFileName.absoluteString.contains("file:///")
                ? scriptFileName.absoluteString[7...]
                : scriptFileName.absoluteString

            let homeDir = gameContext.applicationSettings.paths.rootUrl.absoluteString[7...]

            scriptFilePath = scriptFilePath.replacingOccurrences(of: homeDir, with: "~/").hexDecoededString()

            sendText("[Starting '\(scriptFilePath)' at \(formattedDate)]")

            self.fileName = scriptName
            context.variables["scriptname"] = scriptName
            context.variables["scriptfilepath"] = scriptFilePath

            gameContext.events2.post(ScriptEvent(command: .add, name: self.fileName))
        }

        var index = 0

        for var line in scriptFile.lines {
            index += 1

            if line.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                continue
            }

            if let includeMatch = includeRegex.firstMatch(&line) {
                guard let include = includeMatch.valueAt(index: 1) else { continue }
                var includeName = include.trimmingCharacters(in: .whitespaces)
                if includeName.hasSuffix(".cmd") {
                    includeName = String(includeName.dropLast(4)).trimmingCharacters(in: .whitespaces)
                }
                guard includeName != scriptName, includeName != self.fileName else {
                    sendText("script '\(scriptName)' cannot include itself!", preset: "scripterror", scriptLine: index, fileName: scriptName)
                    continue
                }
                sendText("including '\(includeName)'", preset: "scriptecho", scriptLine: index, fileName: scriptName)
                initialize(includeName, isInclude: true)
            } else {
                let scriptLine = ScriptLine(
                    line.trimmingCharacters(in: .whitespacesAndNewlines),
                    fileName: scriptName,
                    lineNumber: index
                )

                context.lines.append(scriptLine)
            }

            if let labelMatch = labelRegex.firstMatch(&line) {
                guard let label = labelMatch.valueAt(index: 1) else { return }
                let newLabel = Label(name: label.lowercased(), line: context.lines.count - 1, scriptLine: index, fileName: scriptName)
                if let existing = context.labels[label] {
                    sendText("**duplicate label found** replacing label '\(existing.name)' at line \(existing.scriptLine) of '\(existing.fileName)' with '\(newLabel.name)' at line \(newLabel.scriptLine) of '\(newLabel.fileName)'", preset: "scripterror", fileName: scriptName)
                }
                context.labels[label.lowercased()] = newLabel
            }
        }
    }

    func handleLine(_ line: ScriptLine) -> ScriptExecuteResult {
//        print("handling line \(line.lineNumber)")

        guard let token = line.token else {
            sendText("Unknown script command: '\(line.originalText)'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .next
        }

        if let previous = context.previousLine {
            if previous.token?.isTopLevelIf == true, previous.token?.isSingleToken == true, !(token.isElseIfToken || token.isElseToken) {
                context.popIfStack()
            }
        }

        return executeToken(line, token)
    }

    func executeToken(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        if let handler = tokenHandlers[token.description] {
            return handler(line, token)
        }

        sendText("No handler for script command: '\(line.originalText)'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
        return handleError()
    }

    func gotoLabel(_ label: String, _ args: [String], _ isGosub: Bool = false) -> ScriptExecuteResult {
        let result = context.replaceVars(label)

        guard let currentLine = context.currentLine else {
            sendText("Tried to goto \(result) but had no 'currentLine'", preset: "scripterror", fileName: fileName)
            return handleError()
        }

        guard let target = context.labels[result.lowercased()] else {
            guard result.lowercased() != "return" else {
                return gotoReturn(currentLine)
            }
            sendText("label '\(result)' not found", preset: "scripterror", scriptLine: currentLine.lineNumber, fileName: currentLine.fileName)
            return handleError()
        }

        delayedTask.reset()
        matchwait = nil
        matchStack.removeAll()

        // clear any previous regex vars as those get applied before the label vars
        context.regexVars.removeAll()
        context.setLabelVars(args)

        var count = 0
        let displayArgs = args
            .map {
                defer { count += 1 }
                if count > 0, $0.range(of: " ") != nil {
                    return "\"\($0)\""
                }
                return $0
            }
            .joined(separator: " ")

        let command = isGosub ? "gosub" : "goto"

        notify("\(command) '\(result)' \(displayArgs)", debug: ScriptLogLevel.gosubs, scriptLine: currentLine.lineNumber, fileName: currentLine.fileName)

        let line = context.lines[target.line]
        let gosubContext = GosubContext(label: target, line: line, arguments: args, ifStack: context.ifStack.copy(), isGosub: isGosub)

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
        let resolvedPattern = context.replaceVars(pattern).trimmingCharacters(in: CharacterSet(["\""]))

        let message = "action\(nameText) \(action) \(resolvedPattern)"
        notify(message, debug: .actions, scriptLine: line.lineNumber, fileName: line.fileName)

        let trimmed = pattern.trimmingCharacters(in: CharacterSet(["\""]))

        let actionOp = ActionOp(name: name, command: action, pattern: trimmed, line: line)
        actions.append(actionOp)

        return .next
    }

    func handleActionEval(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .actionEval(className, action, expression) = token else {
            return .next
        }

        let classText = className.count > 0 ? " (\(className))" : ""

        let message = "action\(classText) \(action) \(expression.description)"
        notify(message, debug: .actions, scriptLine: line.lineNumber, fileName: line.fileName)

        let actionOp = ActionEvalOp(className: className, command: action, expression: expression, line: line)
        actions.append(actionOp)

        return .next
    }

    func handleActionToggle(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .actionToggle(className, toggle) = token else {
            return .next
        }

        let maybeToggle = context.replaceVars(toggle)
        let enabled = maybeToggle.trimmingCharacters(in: .whitespaces).lowercased().toBool() == true

        notify("action \(className) \(maybeToggle)", debug: .actions, scriptLine: line.lineNumber, fileName: line.fileName)

        let filtered = actions.filter { $0.className == className }

        for var action in filtered {
            action.enabled = enabled
        }

        return .next
    }

    func handleLeftBrace(_: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .leftBrace = token else {
            return .next
        }
        return .next
    }

    func handleRightBrace(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case .rightBrace = token else {
            return .next
        }

        let (popped, ifLine) = context.popIfStack()
        guard popped else {
            sendText("End brace encountered without matching beginning block", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return handleError()
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

    func handleCounter(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .counter(function, number) = token else {
            return .next
        }

        let val = context.variables["c"] ?? "0"
        let existingVariable = context.replaceVars(val)

        guard let existingValue = Double(existingVariable) else {
            sendText("unable to convert '\(existingVariable)' to a number", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .next
        }

        var maybeNumber = number
        if maybeNumber.isEmpty {
            maybeNumber = "0"
        }

        let replacedNumber = context.replaceVars(maybeNumber)
        guard let numberValue = Double(replacedNumber) else {
            sendText("unable to convert '\(replacedNumber)' to a number", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .next
        }

        var result: Double = 0

        switch function.lowercased() {
        case "set":
            result = numberValue

        case "+":
            fallthrough
        case "add":
            result = existingValue + numberValue

        case "-":
            fallthrough
        case "subtract":
            result = existingValue - numberValue

        case "*":
            fallthrough
        case "multiply":
            result = existingValue * numberValue

        case "%":
            fallthrough
        case "mod":
            fallthrough
        case "modulus":
            result = existingValue.truncatingRemainder(dividingBy: numberValue)

        case "/":
            fallthrough
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

        var textResult = "\(result.formattedNumber)"

        if result == rint(result) {
            textResult = "\(Int(result))"
        }

        context.variables["c"] = textResult

        notify("counter: \(existingValue) \(function) \(numberValue) = \(textResult)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

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

    func handleDelay(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .delay(str) = token else {
            return .next
        }

        let maybeNumber = context.replaceVars(str)
        let duration = Double(maybeNumber) ?? 1

        notify("delaying for \(duration) seconds", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        delayedTask.set(duration, queue: lockQueue.queue) {
            self.queueNext()
        }

        return .wait
    }

    func handleEcho(_: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .echo(text) = token else {
            return .next
        }

        let targetText = context.replaceVars(text)

        gameContext.events2.echoText(targetText, preset: "scriptecho", mono: true)
        return .next
    }

    func handleElseIfSingle(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .elseIfSingle(exp, lineToken) = token else {
            return .next
        }

        guard context.ifStack.count > 0 else {
            sendText("Expected there to be a previous 'if' or 'else if'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return handleError()
        }

        var execute = false
        var result = false

        if context.ifStack.last!.ifResult == false {
            execute = true
            context.pushCurrentLineToIfStack()
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

        if result {
            context.ifStack.pop()
            context.pushLineToIfStack(line)
        }

        if execute, result {
            return executeToken(line, lineToken)
        }

        return .advanceToEndOfBlock
    }

    func handleElseIf(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .elseIf(exp) = token else {
            return .next
        }

        guard context.ifStack.count > 0 else {
            sendText("Expected there to be a previous 'if' or 'else if'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return handleError()
        }

        var execute = false
        var result = false

        if context.ifStack.last!.ifResult == false {
            execute = true
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

        if result {
            context.ifStack.pop()
            context.pushLineToIfStack(line)
        }

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
            return handleError()
        }

        if !context.consumeToken(.leftBrace) {
            sendText("Expecting opening bracket", preset: "scripterror", scriptLine: line.lineNumber + 1, fileName: line.fileName)
            return handleError()
        }

        var execute = false
        var result = false

        if context.ifStack.last!.ifResult == false {
            execute = true
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

        if result {
            context.ifStack.pop()
            context.pushLineToIfStack(line)
        }

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
            return handleError()
        }

        var execute = false

        if context.ifStack.last!.ifResult == false {
            execute = true
            context.ifStack.pop()
            context.pushCurrentLineToIfStack()
            line.ifResult = true
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
            return handleError()
        }

        var execute = false

        if context.ifStack.last!.ifResult == false {
            execute = true
            context.ifStack.pop()
            context.pushCurrentLineToIfStack()
            line.ifResult = true
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
            return handleError()
        }

        if !context.consumeToken(.leftBrace) {
            sendText("Expecting opening bracket", preset: "scripterror", scriptLine: line.lineNumber + 1, fileName: line.fileName)
            return handleError()
        }

        var execute = false

        if context.ifStack.last!.ifResult == false {
            execute = true
            context.ifStack.pop()
            context.pushLineToIfStack(line)
            line.ifResult = true
        }

        notify("else: \(execute)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        if execute { return .next }
        return .advanceToNextBlock
    }

    func handleEval(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .eval(variable, expression) = token else {
            return .next
        }

        let targetVar = context.replaceVars(variable)
        let result = funcEvaluator.evaluateStrValue(expression)

        notify("eval \(targetVar) \(result.text) = \(result.result)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        context.variables[targetVar] = result.result

        return .next
    }

    func handleEvalMath(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .evalMath(variable, expression) = token else {
            return .next
        }

        let targetVar = context.replaceVars(variable)
        let result = funcEvaluator.evaluateValue(expression)

        notify("evalmath \(targetVar) \(result.text) = \(result.result)", debug: ScriptLogLevel.if, scriptLine: line.lineNumber, fileName: line.fileName)

        context.variables[targetVar] = result.result

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
            return handleError()
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
            return handleError()
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
            return handleError()
        }

        let replacedLabel = context.replaceVars(label)

        if replacedLabel == "clear" {
            notify("gosub clear", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber, fileName: line.fileName)
            gosubStack.clear()
            context.setLabelVars([""])
            return .next
        }

        let replaced = context.replaceVars(args)
        var arguments: [String] = []

        if !replaced.isEmpty {
            arguments = [replaced] + replaced.argumentsSeperated().map { $0.trimmingCharacters(in: CharacterSet(["\""])) }
        } else {
            arguments = [""]
        }

        return gotoLabel(label, arguments, true)
    }

    func handleGoto(_: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .goto(label, args) = token else {
            return .next
        }

        let replaced = context.replaceVars(args)
        var arguments: [String] = []

        if !replaced.isEmpty {
            arguments = [replaced] + replaced.argumentsSeperated().map { $0.trimmingCharacters(in: CharacterSet(["\""])) }
        } else {
            arguments = [""]
        }

        return gotoLabel(label, arguments)
    }

    func handleLabel(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .label(label) = token else {
            return .next
        }

        notify("passing label '\(label)'", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber, fileName: line.fileName)
        context.variables["lastlabel"] = label
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
        notify("matchwait \(time)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        let token = Matchwait()
        matchwait = token

        if timeout > 0 {
            delayedTask.set(timeout, queue: lockQueue.queue) {
                if let match = self.matchwait, match.id == token.id {
                    self.matchwait = nil
                    self.matchStack.removeAll()
                    self.notify("matchwait timeout", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)
                    self.queueNext()
                }
            }
        }

        return .wait
    }

    func handleMath(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .math(variable, function, number) = token else {
            return .next
        }

        let variableName = context.replaceVars(variable)

        var val = context.variables[variableName] ?? "0"
        if val.isEmpty {
            val = "0"
        }

        let existingVariable = context.replaceVars(val)

        guard let existingValue = Double(existingVariable) else {
            sendText("unable to convert '\(existingVariable)' to a number", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .next
        }

        var maybeNumber = number
        if maybeNumber.isEmpty {
            maybeNumber = "0"
        }

        let replacedNumber = context.replaceVars(maybeNumber)
        guard let numberValue = Double(replacedNumber) else {
            sendText("unable to convert '\(replacedNumber)' to a number", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return .next
        }

        var result: Double = 0

        switch function.lowercased() {
        case "set":
            result = numberValue

        case "+":
            fallthrough
        case "add":
            result = existingValue + numberValue

        case "-":
            fallthrough
        case "subtract":
            result = existingValue - numberValue

        case "*":
            fallthrough
        case "multiply":
            result = existingValue * numberValue

        case "%":
            fallthrough
        case "mod":
            fallthrough
        case "modulus":
            result = existingValue.truncatingRemainder(dividingBy: numberValue)

        case "/":
            fallthrough
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

        var textResult = "\(result.formattedNumber)"

        if result == rint(result) {
            textResult = "\(Int(result))"
        }

        context.variables[variableName] = textResult

        notify("math \(variableName): \(existingValue) \(function) \(numberValue) = \(textResult)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

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
        gameContext.events2.sendCommand(command)

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

        delayedTask.set(duration, queue: lockQueue.queue) {
            self.nextAfterRoundtime()
        }

        return .wait
    }

    func handlePrintBox(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .printbox(text) = token else {
            return .next
        }

        let send = context.replaceVars(text)

        notify("printbox \(send)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        gameContext.events2.sendCommand(Command2(command: "#printbox \(send)"))

        return .next
    }

    func handlePut(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .put(text) = token else {
            return .next
        }

        let send = context.replaceVars(text)

        notify("put \(send)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        let command = Command2(command: send, fileName: fileName)
        gameContext.events2.sendCommand(command)

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

        return gotoReturn(line)
    }

    func gotoReturn(_ line: ScriptLine) -> ScriptExecuteResult {
        guard let ctx = gosubStack.pop(), let returnToLine = ctx.returnToLine, let returnToIndex = ctx.returnToIndex else {
            notify("no gosub to return to!", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber, fileName: line.fileName)
            sendText("no gosub to return to!", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
            return handleError()
        }

        if let prev = gosubStack.last {
            context.setLabelVars(prev.arguments)
        } else {
            context.setLabelVars([""])
        }

        delayedTask.reset()
        matchwait = nil
        matchStack.removeAll()

        context.ifStack = ctx.ifStack.copy()

        notify("returning to line \(returnToLine.lineNumber) of \(returnToLine.fileName)", debug: ScriptLogLevel.gosubs, scriptLine: line.lineNumber, fileName: line.fileName)

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
        gameContext.events2.sendCommand(command)

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

    func handleTimer(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .timer(command, maybeDate) = token else {
            return .next
        }

        let resolvedCommand = context.replaceVars(command)
        let resolvedMaybeDate = context.replaceVars(maybeDate)

        notify("timer \(resolvedCommand) \(resolvedMaybeDate)", debug: ScriptLogLevel.vars, scriptLine: line.lineNumber, fileName: line.fileName)

        switch resolvedCommand.lowercased() {
        case "start":
            context.variables.startTimer()
        case "stop":
            context.variables.stopTimer()
        case "clear":
            context.variables.clearTimer()
        case "setstart":
            let date = DateFormats.parse(resolvedMaybeDate)
            context.variables.startTimer(date)
        default:
            sendText("unknown timer command '\(resolvedCommand)'", preset: "scripterror", scriptLine: line.lineNumber, fileName: line.fileName)
        }

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

        let vars = context.replaceVars(text)

        notify("waiteval \(vars)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

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

        let resolved = context.replaceVars(text)

        notify("waitfor \(resolved)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        reactToStream.append(WaitforOp(text))

        return .wait
    }

    func handleWaitforRe(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        guard case let .waitforre(pattern) = token else {
            return .next
        }

        let resolved = context.replaceVars(pattern)

        notify("waitforre \(resolved)", debug: ScriptLogLevel.wait, scriptLine: line.lineNumber, fileName: line.fileName)

        reactToStream.append(WaitforReOp(pattern))

        return .wait
    }
}
