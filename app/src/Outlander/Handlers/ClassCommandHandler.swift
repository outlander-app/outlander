//
//  ClassCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 5/9/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class ClassCommandHandler : ICommandHandler {

    var command = "#class"

    let validCommands = ["clear", "load", "reload", "list", "save"]

    func handle(command: String, withContext: GameContext) {
        let commands = command[6...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).components(separatedBy: " ")

        if commands.count == 1 && validCommands.contains(commands[0].lowercased()) {
            switch commands[0].lowercased() {
            case "clear":
                withContext.classes.clear()
                withContext.events.echoText("Classes cleared")
                return

            case "load", "reload":
                ClassLoader(LocalFileSystem(withContext.applicationSettings)).load(withContext.applicationSettings, context: withContext)
                withContext.events.echoText("Classes reloaded")
                return

            case "list":
                withContext.events.echoText("")
                withContext.events.echoText("Classes:")
                for c in withContext.classes.all() {
                    let val = c.value ? "on" : "off"
                    withContext.events.echoText("\(c.key): \(val)")
                }
                withContext.events.echoText("")
                return

            case "save":
                ClassLoader(LocalFileSystem(withContext.applicationSettings)).save(withContext.applicationSettings, classes: withContext.classes)
                withContext.events.echoText("Classes saved")
                return
            default:
                return
            }
        } else {
            withContext.classes.parse(commands.joined(separator: " "))
        }
    }
}
