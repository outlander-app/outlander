//
//  Script.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

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
    func load(_: String) -> [String] {
        []
    }
}

enum ScriptExecuteResult {
    case next
    case wait
    case exit
    case advanceToNextBlock
    case advanceToEndOfBlock
}

class Script {
    var started: Date?
    var fileName: String = ""

    private var stackTrace: Stack<ScriptLine>
    private var tokenHandlers: [ScriptTokenValue: (ScriptLine, ScriptTokenValue) -> ScriptExecuteResult]

    var stopped = false
    var paused = false
    var nextAfterUnpause = false

    var tokenizer: ScriptTokenizer
    var loader: IScriptLoader
    var context: ScriptContext

    var includeRegex: Regex
    var labelRegex: Regex

    static var dateFormatter = DateFormatter()

    init(_ fileName: String, loader: IScriptLoader) throws {
        self.fileName = fileName
        self.loader = loader

        tokenizer = ScriptTokenizer()

        stackTrace = Stack<ScriptLine>(30)

        includeRegex = RegexFactory.get("^\\s*include (.+)$")!
        labelRegex = RegexFactory.get("^\\s*(\\w+((\\.|-|\\w)+)?):")!

        context = ScriptContext()
        tokenHandlers = [:]

        Script.dateFormatter.dateFormat = "hh:mm a"
    }

    func run(_: [String]) {
        started = Date()

        let formattedDate = Script.dateFormatter.string(from: started!)

        sendText("[Starting '\(fileName)' at \(formattedDate)]\n")

        initialize(fileName)

        next()
    }

    private func next() {
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
//            line.token = tokenizer.read(line.originalText)
        }

        stackTrace.push(line)

        let result = handleLine(line)

        switch result {
        case .next: next()
        case .wait: return
        case .exit: cancel()
        case .advanceToNextBlock: cancel()
        case .advanceToEndOfBlock: cancel()
        }
    }

    func pause() {
        paused = true
        sendText("[Pausing '\(fileName)']\n")
    }

    func resume() {
        if !paused {
            return
        }

        sendText("[Resuming '\(fileName)']\n")

        paused = false

        if nextAfterUnpause {
            next()
        }
    }

    func cancel() {
        stop()
//        self.notifyExit()
    }

    func stop() {
        if stopped { return }

        stopped = true
        context.currentLineNumber = -1
        let diff = Date().timeIntervalSince(started!)
        sendText("[Script '\(fileName)' completed after \(diff.stringTime)]\n")
    }

    private func sendText(_ text: String, preset: String = "scriptinput", scriptLine: Int = -1, fileName: String = "") {
        let name = fileName == "" ? self.fileName : fileName
        print("\(preset) [\(name) (\(scriptLine))]: \(text)")
    }

    private func initialize(_ fileName: String) {
        let lines = loader.load(fileName)

        if lines.count == 0 {
            sendText("Script '\(fileName)' is empty or does not exist\n", preset: "scripterror")
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
                    sendText("script '\(fileName)' cannot include itself!\n", preset: "scripterror", scriptLine: index, fileName: fileName)
                    continue
                }
//                self.notify("including '\(includeName)'\n", debug: ScriptLogLevel.gosubs, scriptLine: index)
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
                    sendText("replacing label '\(existing.name)' from '\(existing.fileName)'\n", preset: "scripterror", scriptLine: index)
                }
                context.labels[label.lowercased()] = Label(name: label.lowercased(), line: context.lines.count - 1, fileName: fileName)
            }
        }
    }

    func handleLine(_ line: ScriptLine) -> ScriptExecuteResult {
        guard let token = line.token else {
            sendText("Unknown command: '\(line.originalText)'\n", preset: "scripterror", scriptLine: line.lineNumber, fileName: fileName)
            return .next
        }

        return executeToken(line, token)
    }

    func executeToken(_ line: ScriptLine, _ token: ScriptTokenValue) -> ScriptExecuteResult {
        if let handler = tokenHandlers[token] {
            return handler(line, token)
        }

        sendText("No handler for script token: '\(line.originalText)'\n", preset: "scripterror", scriptLine: line.lineNumber, fileName: fileName)
        return .exit
    }
}
