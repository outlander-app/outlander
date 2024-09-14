//
//  EpediaCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/10/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import AppKit
import Foundation

class EpediaCommandHandler: ICommandHandler {
    var command = "#epedia"
    var aliases = ["#epedia", "#wiki", "#drwiki"]

    func canHandle(_ command: String) -> Bool {
        let commands = command.split(separator: " ", maxSplits: 1)
        return commands.count > 0 && aliases.contains(String(commands[0]).lowercased())
    }

    func handle(_ input: String, with _: GameContext) {
        let commands = input.split(separator: " ", maxSplits: 1)
        var text = ""
        if commands.count > 1 {
            text = String(commands[1]).trimLeadingWhitespace()
        }

        var value = "https://elanthipedia.play.net/Main_Page"

        if !text.isEmpty, let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            value = "https://elanthipedia.play.net/index.php?search=\(encoded)&title=Special:Search&go=Go"
        }

        guard let url = URL(string: value) else {
            return
        }

        if url.scheme?.hasPrefix("http") == true {
            NSWorkspace.shared.open(url)
        }
    }
}
