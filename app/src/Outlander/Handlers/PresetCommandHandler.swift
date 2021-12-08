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
            context.events.echoText("Presets cleared")
        case "load", "reload":
            PresetLoader(files).load(context.applicationSettings, context: context)
            context.events.echoText("Presets reloaded")
        case "save":
            PresetLoader(files).save(context.applicationSettings, presets: context.presets)
            context.events.echoText("Presets saved")
        case "help":
            fallthrough
        default:
            displayHelp(context)
        }
    }

    func displayHelp(_ context: GameContext) {
        context.events.echoText("#preset commands:")
        context.events.echoText("  clear, reload, save, help")
        context.events.echoText("  ex:")
        context.events.echoText("    #preset clear")
        context.events.echoText("    #preset reload")
        context.events.echoText("    #preset save")
    }
}