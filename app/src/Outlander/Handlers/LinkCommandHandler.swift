//
//  LinkCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 11/29/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class LinkCommandHandler: ICommandHandler {
    var command = "#link"

    func handle(_ command: String, with context: GameContext) {
        let commands = command[5...].trimmingCharacters(in: .whitespacesAndNewlines)

        guard handleLongFormat(commands, context: context) else {
            _ = handleShortFormat(commands, context: context)
            return
        }
    }

    private func handleLongFormat(_ input: String, context: GameContext) -> Bool {
        var target = input
        guard let mainRegex = RegexFactory.get("^(>([\\w\\.\\$%-]+)\\s)?((#[a-fA-F0-9]+)(,(#[a-fA-F0-9]+))?\\s)?\\{(.+)\\}\\s?\\{(.+)\\}") else {
            return false
        }

        guard let match = mainRegex.firstMatch(&target) else {
            return false
        }

        guard match.count > 0 else {
            return false
        }

        let window = match.valueAt(index: 2) ?? "main"
        let foregroundColor = match.valueAt(index: 4)
        let backgroundColor = match.valueAt(index: 6)
        let text = match.valueAt(index: 7) ?? "link"
        let command = match.valueAt(index: 8) ?? "#echo no command..."

        let tag = TextTag(text: text + "\n", window: window, color: foregroundColor, backgroundColor: backgroundColor, command: command)
        context.events.echoTag(tag)
        return true
    }

    private func handleShortFormat(_ input: String, context: GameContext) -> Bool {
        var target = input
        guard let mainRegex = RegexFactory.get("^(>([\\w\\.\\$%-]+)\\s)((#[a-fA-F0-9]+)(,(#[a-fA-F0-9]+))?\\s)??(\\w+)\\s(.+)") else {
            return false
        }

        guard let match = mainRegex.firstMatch(&target) else {
            return false
        }

        guard match.count > 0 else {
            return false
        }

        let window = match.valueAt(index: 2) ?? "main"
        let foregroundColor = match.valueAt(index: 4)
        let backgroundColor = match.valueAt(index: 6)
        let text = match.valueAt(index: 7) ?? "link"
        let command = match.valueAt(index: 8) ?? "#echo no command..."

        let tag = TextTag(text: text + "\n", window: window, color: foregroundColor, backgroundColor: backgroundColor, command: command)
        context.events.echoTag(tag)
        return true
    }
}
