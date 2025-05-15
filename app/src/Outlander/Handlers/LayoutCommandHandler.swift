//
//  LayoutCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 5/12/25.
//  Copyright © 2025 Joe McBride. All rights reserved.
//

import AppKit
import Foundation

public class LayoutCommandHandler: ICommandHandler {

    private let files: FileSystem
    private let log = LogManager.getLog(String(describing: LayoutCommandHandler.self))

    var command = "#layout"

    let validCommands = ["load", "reload", "save", "settings"]
    let loadCommands = ["load", "reload"]

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ input: String, with context: GameContext) {
        let commands = input.split(separator: " ", maxSplits: 1)
        var text = [String]()
        if commands.count > 1 {
            text = commands[1].trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        }

        guard text.count > 0 else {
            let msg = text.joined()
            context.events2.echoError("'\(msg)' is not a valid layout command")
            return
        }

        var command = "load"
        var fileName = text[0]
        if (validCommands.contains(text[0].lowercased())) {
            command = text[0].lowercased()
            fileName = text.count > 1 ? text[1] : context.applicationSettings.profile.layout
        }

        if (command == "settings") {
            context.events2.toggleLayoutSettings()
            return
        }

        if (!fileName.hasSuffix(".cfg")) {
            fileName = "\(fileName).cfg"
        }

        let filePath = context.applicationSettings.paths.layout.appendingPathComponent(fileName)

        if loadCommands.contains(command), !files.fileExists(filePath) {
            context.events2.echoError("Layout '\(fileName)' does not exist")
            return
        }

        switch command {
        case "save":
            context.events2.saveLayout(fileName)
            context.events2.echoText("Saved layout: \(fileName)")
            return
        case "reload", "load":
            context.events2.loadLayout(fileName)
            context.events2.echoText("Loaded layout: \(fileName)")
            return
        default:
            return
        }
    }
}
