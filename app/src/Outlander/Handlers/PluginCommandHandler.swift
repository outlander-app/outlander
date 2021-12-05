//
//  PluginCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/4/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class PluginCommandHandler: ICommandHandler {
    var command = "#plugin"

    let validCommands = ["load", "reload", "unload", "list", "help"]

    func handle(_ input: String, with context: GameContext) {
        let commands = input[command.count...].trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ").filter { !$0.isEmpty }

        guard commands.count >= 1 else {
            displayHelp(context)
            return
        }

        if commands.count >= 1, validCommands.contains(commands[0].lowercased()) {
            switch commands[0].lowercased() {
            case "load", "reload":
                let pluginName = commands.count > 1 ? commands[1] : ""
                guard !pluginName.isEmpty else {
                    context.events.echoError("Plugin name not specified")
                    return
                }
                context.events.echoText("Reloading \(pluginName)")
                context.events.post("ol:plugin", data: ("load", pluginName))
            case "unload":
                let pluginName = commands.count > 1 ? commands[1] : ""
                guard !pluginName.isEmpty else {
                    context.events.echoError("Plugin name not specified")
                    return
                }
                context.events.echoText("Unloading \(pluginName)")
                context.events.post("ol:plugin", data: ("unload", pluginName))
            default:
                displayHelp(context)
            }
        }
    }

    func displayHelp(_ context: GameContext) {
        context.events.echoText("#plugin")
        context.events.echoText("  \(validCommands.joined(separator: ", "))")
    }
}
