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

    let validCommands = ["save", "load", "reload"]

    func handle(_ command: String, with context: GameContext) {
        var commands = command[4...].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).components(separatedBy: " ")

        if commands.count == 1, validCommands.contains(commands[0].lowercased()) {
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

        if commands.count > 1 {
            let key = commands[0]
            commands.remove(at: 0)
            let value = commands.joined(separator: " ")

            context.globalVars[key] = value
        }
    }
}
