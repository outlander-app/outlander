//
//  WindowCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 5/1/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class WindowCommandHandler: ICommandHandler {
    let command = "#window"

    let validCommands = ["add", "clear", "hide", "list", "reload", "remove", "load", "show"]
    let regex = try? Regex("^(\\w+)(\\s(\\w+))?$")
    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ command: String, with context: GameContext) {
        var commands = command[7...].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if commands.hasPrefix("reload") || commands.hasPrefix("load") {
            let loader = WindowLayoutLoader(files)
            if let layout = loader.load(context.applicationSettings, file: context.applicationSettings.profile.layout) {
                context.layout = layout
                context.events.post("ol:window", data: ["action": "reload", "window": ""])
            }
            return
        }

        guard let matches = regex?.firstMatch(&commands) else {
            return
        }

        let action = matches.valueAt(index: 1) ?? ""
        let window = matches.valueAt(index: 3) ?? ""

        if validCommands.contains(action) {
            context.events.post("ol:window", data: ["action": action, "window": window.lowercased()])
        }
    }
}
