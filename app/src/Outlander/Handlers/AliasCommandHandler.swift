//
//  AliasCommandHandler.swift
//  Outlander
//
//  Created by Eitan Romanoff on 5/24/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class AliasCommandHandler: ICommandHandler {
    var command = "#alias"
    let aliasAddRegex = try? Regex("add \\{(.*?)\\} \\{(.*?)\\}(?:\\s\\{(.*?)\\})?", options: [.caseInsensitive])

    let validCommands = ["add", "load", "reload", "list", "save", "clear"]

    func handle(_ command: String, with context: GameContext) {
        let commandStripped = command[6...].trimmingCharacters(in: .whitespacesAndNewlines)
        let commandTokens = commandStripped.components(separatedBy: " ")

        if commandTokens.count >= 1, validCommands.contains(commandTokens[0].lowercased()) {
            switch commandTokens[0].lowercased() {
            case "add":
                if aliasAddRegex?.hasMatches(commandStripped) ?? false {
                    var aliasStr = "\(self.command) \(commandStripped[4...])"
                    guard let alias = Alias.from(alias: &aliasStr) else {
                        return
                    }

                    let added = context.upsertAlias(alias: alias)
                    context.events2.echoText(added ? "Alias added" : "Alias updated")
                } else {
                    context.events2.echoText("Invalid syntax. Usage: #alias add {pattern} {replace} {class}")
                }
                return

            case "clear":
                context.aliases = []
                context.events2.echoText("Aliases cleared")
                return

            case "load", "reload":
                AliasLoader(LocalFileSystem(context.applicationSettings)).load(context.applicationSettings, context: context)
                context.events2.echoText("Aliases reloaded")
                return

            case "save":
                AliasLoader(LocalFileSystem(context.applicationSettings)).save(context.applicationSettings, aliases: context.aliases)
                context.events2.echoText("Aliases saved")
                return

            case "list":
                fallthrough
            default:
                context.events2.echoText("")

                if context.aliases.isEmpty {
                    context.events2.echoText("There are no aliases saved.")
                }

                context.events2.echoText("Aliases:")
                for alias in context.aliases {
                    context.events2.echoText(String(describing: alias))
                }
                context.events2.echoText("")
                return
            }
        }
    }
}
