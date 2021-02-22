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
        context.events.post("ol:runscript", data: commands)
    }
}

class ScriptCommandHandler: ICommandHandler {
    var command = "#script"

    func handle(_ command: String, with context: GameContext) {
        let commands = command[7...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        context.events.post("ol:script", data: commands)
    }
}
