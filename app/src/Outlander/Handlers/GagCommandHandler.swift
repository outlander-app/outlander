//
//  GagCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 5/9/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class GagCommandHandler: ICommandHandler {
    var command = "#gag"
    let gagAddRegex = try? Regex("add \\{(.*?)\\}(?:\\s\\{(.*?)\\})?", options: [.caseInsensitive])

    let validCommands = ["add", "clear", "load", "reload", "list", "save"]

    func handle(_ command: String, with context: GameContext) {
        let commandStripped = command[4...].trimmingCharacters(in: .whitespacesAndNewlines)
        let commandTokens = commandStripped.components(separatedBy: " ")

        if commandTokens.count >= 1, validCommands.contains(commandTokens[0].lowercased()) {
            switch commandTokens[0].lowercased() {
            case "add":
                if gagAddRegex?.hasMatches(commandStripped) ?? false {
                    var gagStr = "#gag \(commandStripped[4...])"
                    guard let gag = Gag.from(gag: &gagStr) else {
                        return
                    }
                    let added = context.upsertGag(gag: gag)
                    context.events2.echoText(added ? "Gag added" : "Gag already exists")
                } else {
                    context.events2.echoText("Invalid syntax. Usage: #gag add {gag} {class}")
                }
                return

            case "clear":
                context.gags = []
                context.events2.echoText("Gags cleared")
                return

            case "load", "reload":
                GagLoader(LocalFileSystem(context.applicationSettings)).load(context.applicationSettings, context: context)
                context.events2.echoText("Gags reloaded")
                return

            case "save":
                GagLoader(LocalFileSystem(context.applicationSettings)).save(context.applicationSettings, gags: context.gags)
                context.events2.echoText("Gags saved")
                return

            case "list":
                fallthrough
            default:
                context.events2.echoText("")

                if context.gags.isEmpty {
                    context.events2.echoText("There are no gags saved.")
                    return
                }

                context.events2.echoText("Gags:")
                for gag in context.gags {
                    context.events2.echoText(String(describing: gag))
                }
                context.events2.echoText("")
                return
            }
        }
    }
}
