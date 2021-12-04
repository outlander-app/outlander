//
//  ScriptCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 2/19/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class ScriptRunnerCommandHandler: ICommandHandler {
    var command = "."

    func canHandle(_ command: String) -> Bool {
        command.hasPrefix(".")
    }

    func handle(_ command: String, with context: GameContext) {
        let input = command.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        let split = input.components(separatedBy: " ")
        let name = (split.first ?? "").lowercased().trimmingCharacters(in: .whitespaces)
        let maybeArguments = split.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)

        context.events.post("ol:script:run", data: ["name": name, "arguments": maybeArguments])
    }
}

class ScriptCommandHandler: ICommandHandler {
    var command = "#script"

    let validCommands = ["abort", "pause", "resume", "stop", "debug", "trace", "stacktrace", "vars"]

    func handle(_ input: String, with context: GameContext) {
        let commands = input[command.count...].trimmingCharacters(in: .whitespacesAndNewlines)
        let commandTokens = commands.components(separatedBy: " ")

        guard commandTokens.count >= 1, validCommands.contains(commandTokens[0].lowercased()) else {
            let joined = validCommands.joined(separator: ", ")
            context.events.echoText("'\(commandTokens[0])' is not a valid #script command. Valid commands:\n  \(joined)", preset: "scripterror", mono: true)
            return
        }

        context.events.post("ol:script", data: commands.lowercased())
    }
}
