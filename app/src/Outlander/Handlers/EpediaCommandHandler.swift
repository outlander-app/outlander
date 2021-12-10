//
//  EpediaCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/10/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import AppKit

class EpediaCommandHandler: ICommandHandler {
    var command = "#epedia"

    func handle(_ input: String, with context: GameContext) {
        let text = input[command.count...].trimLeadingWhitespace()

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
