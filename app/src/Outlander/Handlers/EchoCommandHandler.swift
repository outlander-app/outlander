//
//  EchoCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 4/24/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class EchoCommandHandler : ICommandHandler {

    var command = "#echo"
    
    let regex = try? Regex("^(>(\\w+)\\s)?((#[a-fA-F0-9]+)(,(#[a-fA-F0-9]+))?\\s)?(.*)")

    func handle(command: String, withContext: GameContext) {
        var commands = command[5...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)

        guard let groups = self.regex?.firstMatch(&commands) else {
            return
        }

        let window = groups.valueAt(index: 2) ?? ""
        let foregroundColor = groups.valueAt(index: 4)
        let backgroundColor = groups.valueAt(index: 6)
        let text = groups.valueAt(index: 7) ?? ""

        var tag = TextTag(text: "\(text)\n", window: window)
        tag.color = foregroundColor
        tag.backgroundColor = backgroundColor
        tag.mono = true
        tag.preset = "scriptecho"

        withContext.events.post("ol:echo", data: tag)
    }
}
