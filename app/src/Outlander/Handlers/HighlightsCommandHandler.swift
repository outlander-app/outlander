//
//  HighlightsCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/7/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class HighlightsCommandHandler: ICommandHandler {
    var command = "#highlight"

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
            context.highlights.removeAll()
            context.events2.echoText("Highlights cleared")
        case "load", "reload":
            HighlightLoader(files).load(context.applicationSettings, context: context)
            context.events2.echoText("Highlights reloaded")
        case "save":
            HighlightLoader(files).save(context.applicationSettings, highlights: context.highlights.all())
            context.events2.echoText("Highlights saved")
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
