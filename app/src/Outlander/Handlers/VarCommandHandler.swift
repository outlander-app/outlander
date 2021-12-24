//
//  VarCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class VarCommandHandler: ICommandHandler {
    var command = "#var"

    let aliases = ["#var", "#tvar"]
    let validCommands = ["save", "load", "reload"]

    func canHandle(_ command: String) -> Bool {
        let commands = command.split(separator: " ", maxSplits: 1)
        return commands.count > 0 && aliases.contains(String(commands[0]).lowercased())
    }

    func handle(_ input: String, with context: GameContext) {
        let commands = input.split(separator: " ", maxSplits: 1)
        var text = [String]()
        if commands.count > 1 {
            text = commands[1].trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        }

        if text.count == 1, validCommands.contains(text[0].lowercased()) {
            switch commands[0].lowercased() {
            case "save":
                VariablesLoader(LocalFileSystem(context.applicationSettings)).save(context.applicationSettings, variables: context.globalVars)
                context.events.echoText("saved variables")
                return
            case "load", "reload":
                VariablesLoader(LocalFileSystem(context.applicationSettings)).load(context.applicationSettings, context: context)
                context.events.echoText("reloaded variables \(context.globalVars.count)")
                return
            default:
                return
            }
        }

        if text.count > 0 {
            let key = text[0]
            text.remove(at: 0)
            let value = text.joined(separator: " ")

            context.globalVars[key] = value
        }
    }
}
