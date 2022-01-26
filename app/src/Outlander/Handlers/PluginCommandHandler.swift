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
                    context.events2.echoError("Plugin name not specified")
                    return
                }
                context.events2.echoText("Reloading \(pluginName)")
                context.events2.post(PluginEvent(command: "load", name: pluginName))
            case "unload":
                let pluginName = commands.count > 1 ? commands[1] : ""
                guard !pluginName.isEmpty else {
                    context.events2.echoError("Plugin name not specified")
                    return
                }
                context.events2.echoText("Unloading \(pluginName)")
                context.events2.post(PluginEvent(command: "unload", name: pluginName))
            default:
                displayHelp(context)
            }
        }
    }

    func displayHelp(_ context: GameContext) {
        context.events2.echoText("#plugin")
        context.events2.echoText("  \(validCommands.joined(separator: ", "))")
    }
}
