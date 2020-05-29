//
//  ClassCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 5/9/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class ClassCommandHandler: ICommandHandler {
    var command = "#class"

    let validCommands = ["clear", "load", "reload", "list", "save"]

    func handle(_ command: String, with context: GameContext) {
        let commands = command[6...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).components(separatedBy: " ")

        if commands.count == 1, validCommands.contains(commands[0].lowercased()) {
            switch commands[0].lowercased() {
            case "clear":
                context.classes.clear()
                context.events.echoText("Classes cleared")
                return

            case "load", "reload":
                ClassLoader(LocalFileSystem(context.applicationSettings)).load(context.applicationSettings, context: context)
                context.events.echoText("Classes reloaded")
                return

            case "list":
                context.events.echoText("")
                context.events.echoText("Classes:")
                for c in context.classes.all() {
                    let val = c.value ? "on" : "off"
                    context.events.echoText("\(c.key): \(val)")
                }
                context.events.echoText("")
                return

            case "save":
                ClassLoader(LocalFileSystem(context.applicationSettings)).save(context.applicationSettings, classes: context.classes)
                context.events.echoText("Classes saved")
                return
            default:
                return
            }
        } else {
            context.classes.parse(commands.joined(separator: " "))
        }
    }
}
