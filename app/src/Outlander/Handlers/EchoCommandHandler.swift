//
//  EchoCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 4/24/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class EchoCommandHandler: ICommandHandler {
    var command = "#echo"

    let regex = try? Regex("^(>(\\w+)\\s)?((#[a-fA-F0-9]+)(,(#[a-fA-F0-9]+))?\\s)?(.*)", options: [.dotMatchesLineSeparators])

    func handle(_ command: String, with: GameContext) {
        guard command.count > 5 else {
            return
        }

        var commands = command[6...]

        guard let groups = regex?.firstMatch(&commands) else {
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

        with.events.post("ol:echo", data: tag)
    }
}
