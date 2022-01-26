//
//  SubsCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/3/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class SubsCommandHandler: ICommandHandler {
    var command = "#subs"

    let validCommands = ["clear", "reload", "load", "save", "help"]

    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ input: String, with context: GameContext) {
        let commands = input[command.count...].trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")

        guard commands.count == 1, validCommands.contains(commands[0].lowercased()) else {
            displayHelp(context)
            return
        }

        switch commands[0].lowercased() {
        case "clear":
            context.substitutes.removeAll()
            context.events2.echoText("Subs cleared")
        case "load", "reload":
            SubstituteLoader(files).load(context.applicationSettings, context: context)
            context.events2.echoText("Subs reloaded")
        case "save":
            SubstituteLoader(files).save(context.applicationSettings, subsitutes: context.substitutes.all())
            context.events2.echoText("Subs saved")
        case "help":
            fallthrough
        default:
            displayHelp(context)
        }
    }

    func displayHelp(_ context: GameContext) {
        context.events2.echoText("#subs commands:")
        context.events2.echoText("  clear, reload, save, help")
        context.events2.echoText("  ex:")
        context.events2.echoText("    #subs clear")
        context.events2.echoText("    #subs reload")
        context.events2.echoText("    #subs save")
    }
}
