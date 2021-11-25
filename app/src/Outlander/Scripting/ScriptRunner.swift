//
//  ScriptRunner.swift
//  Outlander
//
//  Created by Joe McBride on 2/19/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class ScriptRunner: StreamHandler {
    private var context: GameContext
    private var loader: IScriptLoader

    private var scripts: [Script] = []

    init(_ context: GameContext, loader: IScriptLoader) {
        self.context = context
        self.loader = loader

        self.context.events.handle(self, channel: "ol:script:run") { result in
            guard let arguments = result as? [String: String] else {
                return
            }

            guard let scriptName = arguments["name"] else {
                return
            }

            let scriptArgs = arguments["arguments"] ?? ""

            self.run(scriptName, arguments: scriptArgs.argumentsSeperated())
        }

        self.context.events.handle(self, channel: "ol:script") { result in
            guard let commands = result as? String else {
                return
            }

            self.manage(commands)
        }

        self.context.events.handle(self, channel: "ol:script:complete") { result in
            guard let scriptName = result as? String else {
                return
            }

            self.remove([scriptName])
        }

        self.context.events.handle(self, channel: "ol:game:parse") { result in
            guard let data = result as? String else {
                return
            }

            self.stream(data, [])
        }
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
                context.events.echoError("Script '\(scriptName)' does not exist.")
                return
            }

            if let previous = scripts.first(where: { $0.fileName == scriptName }) {
                previous.cancel()
            }

            let script = try Script(scriptName, loader: loader, gameContext: context)
            scripts.append(script)
            script.run(arguments)
        } catch {
            context.events.echoError("An error occurred running script '\(scriptName)'.")
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
//        let param1 = commands.count > 2 ? commands[2] : ""
//        let param2 = commands.count > 3 ? commands[3] : ""

        switch command {
        case "abort":
            abort(scriptName)
        case "pause":
            pause(scriptName)
        case "resume":
            resume(scriptName)
        default:
            context.events.echoText("unhandled script command \(command)", preset: "scripterror", mono: true)
        }
    }

    private func abort(_ scriptName: String) {
        let aborting = scriptName == "all" ? scripts : scripts.filter { $0.fileName.lowercased() == scriptName.lowercased() }

        for script in aborting {
            script.cancel()
            remove([script.fileName])
        }
    }

    private func pause(_ scriptName: String) {
        let pausing = scriptName == "all" ? scripts : scripts.filter { $0.fileName.lowercased() == scriptName.lowercased() }

        for script in pausing {
            script.pause()
        }
    }

    private func resume(_ scriptName: String) {
        let target = scriptName == "all" ? scripts : scripts.filter { $0.fileName.lowercased() == scriptName.lowercased() }

        for script in target {
            script.resume()
        }
    }

    private func remove(_ scriptNames: [String]) {
        for name in scriptNames {
            guard let idx = scripts.firstIndex(where: { $0.fileName.lowercased() == name }) else {
                continue
            }

            scripts.remove(at: idx)
        }
    }
}
