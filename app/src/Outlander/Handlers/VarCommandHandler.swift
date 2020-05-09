//
//  VarCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class VarCommandHandler : ICommandHandler {

    var command = "#var"

    let validCommands = ["save", "load", "reload"]

    func handle(command: String, withContext: GameContext) {
        var commands = command[4...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).components(separatedBy: " ")
        
        if commands.count == 1 && validCommands.contains(commands[0].lowercased()) {
            switch commands[0].lowercased() {
            case "save":
                print("save vars")
                return
            case "load", "reload":
                print("reload vars")
                return
            default:
                return
            }
        }

        if commands.count > 1 {
            let key = commands[0]
            commands.remove(at: 0)
            let value = commands.joined(separator: " ")
            
            withContext.globalVars[key] = value
        }
    }
}
