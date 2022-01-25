//
//  ParseCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 2/26/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class ParseCommandHandler: ICommandHandler {
    var command = "#parse"

    func canHandle(_ command: String) -> Bool {
        if command.hasPrefix("/") {
            return true
        }

        let commands = command.split(separator: " ", maxSplits: 1)
        return commands.count > 0 && commands[0].lowercased() == "#parse"
    }

    func handle(_ text: String, with context: GameContext) {
        var commandLength = command.count
        if text.hasPrefix("/") {
            commandLength = 1
        }

        let data = text[commandLength...].trimmingCharacters(in: .whitespacesAndNewlines)
        context.events.post("ol:game:parse", data: data)
    }
}
