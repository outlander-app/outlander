//
//  PresetCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/2/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class PresetCommandHandler: ICommandHandler {
    var command = "#preset"

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
            context.presets.removeAll()
            context.events2.echoText("Presets cleared")
        case "load", "reload":
            PresetLoader(files).load(context.applicationSettings, context: context)
            context.events2.echoText("Presets reloaded")
        case "save":
            PresetLoader(files).save(context.applicationSettings, presets: context.presets)
            context.events2.echoText("Presets saved")
        case "help":
            fallthrough
        default:
            displayHelp(context)
        }
    }

    func displayHelp(_ context: GameContext) {
        context.events2.echoText("#preset commands:")
        context.events2.echoText("  clear, reload, save, help")
        context.events2.echoText("  ex:")
        context.events2.echoText("    #preset clear")
        context.events2.echoText("    #preset reload")
        context.events2.echoText("    #preset save")
    }
}
