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

    func handle(_ input: String, with context: GameContext) {
        let commands = input[command.count...].trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ").filter { !$0.isEmpty }

        guard commands.count >= 1 else {
            displayHelp(context)
            return
        }

        if commands.count == 1, validCommands.contains(commands[0].lowercased()) {
            switch commands[0].lowercased() {
            case "clear":
                context.classes.clear()
                context.updateClassFilters()
                context.events2.echoText("Classes cleared")
                return

            case "load", "reload":
                ClassLoader(files).load(context.applicationSettings, context: context)
                context.updateClassFilters()
                context.events2.echoText("Classes reloaded")
                return

            case "list":
                context.events2.echoText("")
                context.events2.echoText("Classes:")
                for c in context.classes.all() {
                    let val = c.value ? "on" : "off"
                    context.events2.echoText("\(c.key): \(val)")
                }
                context.events2.echoText("")
                return

            case "save":
                ClassLoader(files).save(context.applicationSettings, classes: context.classes)
                context.events2.echoText("Classes saved")
                return
            case "help":
                fallthrough
            default:
                displayHelp(context)
                return
            }
        } else {
            context.classes.parse(commands.joined(separator: " "))
            context.updateClassFilters()
        }
    }

    func displayHelp(_ context: GameContext) {
        context.events2.echoText("#class commands:")
        context.events2.echoText("  clear, list, reload, save, help")
        context.events2.echoText("  Classes can be assigned to other other application features, such as highlights, triggers, and substitutions, to be able to filter what is currently applied. These classes can be toggled on/off.")
        context.events2.echoText("  Use short syntax with leading +/- and multiple class names, or a single class name with +/- or on/off.")
        context.events2.echoText("  Use the keyword 'all' to toggle all classes.")
        context.events2.echoText("  ex:")
        context.events2.echoText("    #class list")
        context.events2.echoText("    #class reload")
        context.events2.echoText("    #class -all +combat")
        context.events2.echoText("    #class +all -combat")
        context.events2.echoText("    #class -analyze -appraise +combat")
        context.events2.echoText("    #class combat on")
        context.events2.echoText("    #class combat off")
    }
}
