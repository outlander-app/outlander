//
//  ScriptRunner.swift
//  Outlander
//
//  Created by Joe McBride on 2/19/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

struct ScriptRunEvent: Event {
    var name: String
    var arguments: String
}

struct ScriptManageEvent: Event {
    var commands: String
}

struct ScriptCompleteEvent: Event {
    var name: String
}

enum ScriptCommand {
    case add
    case abort
    case resume
    case pause
}

struct ScriptEvent: Event {
    var command: ScriptCommand
    var name: String
}

class ScriptRunner: StreamHandler {
    // private let runQueue = DispatchQueue(label: "com.outlanderapp.scriptrunner.\(UUID().uuidString)", attributes: .concurrent)
    private var context: GameContext
    private var loader: IScriptLoader

    private var scripts: [Script] = []

    init(_ context: GameContext, loader: IScriptLoader) {
        self.context = context
        self.loader = loader

        self.context.events2.register(self) { (evt: ScriptRunEvent) in
            self.run(evt.name, arguments: evt.arguments.argumentsSeperated())
        }

        self.context.events2.register(self) { (evt: ScriptManageEvent) in
            self.manage(evt.commands)
        }

        self.context.events2.register(self) { (evt: ScriptCompleteEvent) in
            self.remove([evt.name])
        }
    }

    deinit {
        self.context.events2.unregister(self, DummyEvent<ScriptRunEvent>())
        self.context.events2.unregister(self, DummyEvent<ScriptManageEvent>())
        self.context.events2.unregister(self, DummyEvent<ScriptCompleteEvent>())
    }

    func stream(_ data: String, _ tokens: [StreamCommand]) {
        for script in scripts {
            script.stream(data, tokens)
        }
    }

    func stream(_ data: String, with _: GameContext) {
        for script in scripts {
            script.stream(data, [])
        }
    }

    private func run(_ scriptName: String, arguments: [String]) {
        do {
            guard loader.exists(scriptName) else {
                context.events2.echoError("Script '\(scriptName)' does not exist.")
                return
            }

            if let previous = scripts.first(where: { $0.matchesName(scriptName) }) {
                previous.cancel()
            }

            let script = try Script(scriptName, loader: loader, gameContext: context)
            scripts.append(script)
            updateActiveScriptVars()
            script.run(arguments)
        } catch {
            context.events2.echoError("An error occurred running script '\(scriptName)'.")
        }
    }

    private func parse(_ data: String) {
        stream(data, [])
    }

    private func manage(_ text: String) {
        let commands = text.components(separatedBy: " ")

        guard commands.count > 1 else {
            return
        }

        let command = commands[0]
        let scriptName = commands[1]
        let param1 = commands.count > 2 ? commands[2] : ""
        let rest = Array(commands.dropFirst(2))
        var except: [String] = []

        if rest.count > 0, rest[0].lowercased() == "except" {
            except = Array(rest.dropFirst())
        }

        switch command {
        case "abort", "stop":
            abort(scriptName, except: except)
        case "pause":
            pause(scriptName, except: except)
        case "resume":
            resume(scriptName, except: except)
        case "debug":
            debug(scriptName, level: param1)
        case "trace", "stacktrace":
            stacktrace(scriptName)
        case "vars":
            vars(scriptName)
        default:
            context.events2.echoText("unhandled script command \(command)", preset: "scripterror", mono: true)
        }
    }

    private func abort(_ scriptName: String, except: [String]) {
        let aborting = scriptName == "all"
            ? scripts.filter { !except.contains($0.fileName.lowercased()) }
            : scripts.filter { $0.fileName.lowercased() == scriptName.lowercased() }

        for script in aborting {
            script.cancel()
            remove([script.fileName])
        }

        updateActiveScriptVars()
    }

    private func pause(_ scriptName: String, except: [String]) {
        let pausing = scriptName == "all"
            ? scripts.filter { !except.contains($0.fileName.lowercased()) }
            : scripts.filter { $0.fileName.lowercased() == scriptName.lowercased() }

        for script in pausing {
            script.pause()
            context.events2.post(ScriptEvent(command: .pause, name: script.fileName))
        }

        updateActiveScriptVars()
    }

    private func resume(_ scriptName: String, except: [String]) {
        let resuming = scriptName == "all"
            ? scripts.filter { !except.contains($0.fileName.lowercased()) }
            : scripts.filter { $0.fileName.lowercased() == scriptName.lowercased() }

        for script in resuming {
            script.resume()
            context.events2.post(ScriptEvent(command: .resume, name: script.fileName))
        }

        updateActiveScriptVars()
    }

    private func remove(_ scriptNames: [String]) {
        for name in scriptNames {
            guard let idx = scripts.firstIndex(where: { $0.fileName.lowercased() == name.lowercased() }) else {
                continue
            }

            scripts.remove(at: idx)

            context.events2.post(ScriptEvent(command: .abort, name: name))
            updateActiveScriptVars()
        }
    }

    private func debug(_ scriptName: String, level: String) {
        guard let number = Int(level), let scriptLevel = ScriptLogLevel(rawValue: number) else {
            return
        }

        let target = scriptName == "all" ? scripts : scripts.filter { $0.fileName.lowercased() == scriptName.lowercased() }

        for script in target {
            script.setLogLevel(scriptLevel)
        }
    }

    private func stacktrace(_ scriptName: String) {
        let target = scriptName == "all" ? scripts : scripts.filter { $0.fileName.lowercased() == scriptName.lowercased() }

        for script in target {
            script.printStacktrace()
        }
    }

    private func vars(_ scriptName: String) {
        let target = scriptName == "all" ? scripts : scripts.filter { $0.fileName.lowercased() == scriptName.lowercased() }

        for script in target {
            script.printVars()
        }
    }

    private func updateActiveScriptVars() {
        let active = scripts.filter { !$0.paused }.map { $0.fileName }
        let paused = scripts.filter { $0.paused }.map { $0.fileName }

        context.globalVars["scriptlist"] = (active + paused).joined(separator: "|")
        context.globalVars["activescriptlist"] = active.joined(separator: "|")
        context.globalVars["pausedscriptlist"] = paused.joined(separator: "|")
    }
}
