//
//  MacroCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 9/23/22.
//  Copyright © 2022 Joe McBride. All rights reserved.
//

import Foundation

class MacroCommandHandler: ICommandHandler {
    var command = "#macro"
    var aliases = ["#macro", "#macros"]

    let validCommands = ["clear", "reload", "load", "save", "help"]

    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func canHandle(_ command: String) -> Bool {
        let commands = command.split(separator: " ", maxSplits: 1)
        return commands.count > 0 && aliases.contains(String(commands[0]).lowercased())
    }

    func handle(_ input: String, with context: GameContext) {
        let commands = input.split(separator: " ", maxSplits: 1)
        var command = ""
        if commands.count > 1 {
            command = String(commands[1]).trimLeadingWhitespace().lowercased()
        }

        guard validCommands.contains(command) else {
            displayHelp(context)
            return
        }

        switch command {
        case "clear":
            context.macros.removeAll()
            context.events2.echoText("Macros cleared")
        case "load", "reload":
            MacroLoader(files).load(context.applicationSettings, context: context)
            context.events2.echoText("Macros reloaded")
        case "save":
            MacroLoader(files).save(context.applicationSettings, macros: context.macros)
            context.events2.echoText("Macros saved")
        case "help":
            fallthrough
        default:
            displayHelp(context)
        }
    }
    
    func displayHelp(_ context: GameContext) {
        context.events2.echoText("\(command) commands:")
        context.events2.echoText("  clear, reload, save, help")
        context.events2.echoText("  ex:")
        context.events2.echoText("    \(command) clear")
        context.events2.echoText("    \(command) reload")
        context.events2.echoText("    \(command) save")
    }
}
