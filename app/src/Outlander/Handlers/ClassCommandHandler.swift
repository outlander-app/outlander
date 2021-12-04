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

    let validCommands = ["clear", "load", "reload", "list", "save", "help"]

    var files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ command: String, with context: GameContext) {
        let commands = command[6...].trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")

        guard commands.count >= 1, validCommands.contains(commands[0].lowercased()) else {
            displayHelp(context)
            return
        }

        if commands.count == 1, validCommands.contains(commands[0].lowercased()) {
            switch commands[0].lowercased() {
            case "clear":
                context.classes.clear()
                context.updateClassFilters()
                context.events.echoText("Classes cleared")
                return

            case "load", "reload":
                ClassLoader(files).load(context.applicationSettings, context: context)
                context.updateClassFilters()
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
                ClassLoader(files).save(context.applicationSettings, classes: context.classes)
                context.events.echoText("Classes saved")
                return
            case "help":
                fallthrough
            default:
                displayHelp(context)
                return
            }
        } else {
            context.classes.parse(commands.joined(separator: " "))
        }
    }

    func displayHelp(_ context: GameContext) {
        context.events.echoText("#class commands:")
        context.events.echoText("  clear, list, reload, save, help")
        context.events.echoText("  Classes can be assigned to other other application features, such as highlights, triggers, and substitutions, to be able to filter what is currently applied. These classes can be toggled on/off.")
        context.events.echoText("  Use short syntax with leading +/- and multiple class names, or a single class name with +/- or on/off.")
        context.events.echoText("  Use the keyword 'all' to toggle all classes.")
        context.events.echoText("  ex:")
        context.events.echoText("    #class list")
        context.events.echoText("    #class reload")
        context.events.echoText("    #class -all +combat")
        context.events.echoText("    #class +all -combat")
        context.events.echoText("    #class -analyze -appraise +combat")
        context.events.echoText("    #class combat on")
        context.events.echoText("    #class combat off")
    }
}
