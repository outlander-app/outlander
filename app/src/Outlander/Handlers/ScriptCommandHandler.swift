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
        return command.hasPrefix(".")
    }

    func handle(_ command: String, with context: GameContext) {
        let commands = command.dropFirst().trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        context.events.post("ol:script:run", data: commands)
    }
}

class ScriptCommandHandler: ICommandHandler {
    var command = "#script"
    
    let validCommands = ["abort", "pause", "resume", "stop"]

    func handle(_ command: String, with context: GameContext) {
        let commands = command[7...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        let commandTokens = commands.components(separatedBy: " ")

        guard commandTokens.count >= 1, validCommands.contains(commandTokens[0].lowercased()) else {
            let joined = validCommands.joined(separator: ", ")
            context.events.echoText("'\(commandTokens[0])' is not a valid #script command. Valid commands:\n  \(joined)", preset: "scripterror", mono: true)
            return
        }

        context.events.post("ol:script", data: commands.lowercased())
    }
}
