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

    let validCommands = ["clear", "reload", "load", "save"]

    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ command: String, with context: GameContext) {
        let commands = command[7...].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).components(separatedBy: " ")

        guard commands.count > 0 else {
            return
        }

        if commands.count == 1, validCommands.contains(commands[0].lowercased()) {
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
            default:
                break
            }
        }
    }
}
