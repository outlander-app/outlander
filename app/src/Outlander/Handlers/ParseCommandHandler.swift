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

    func handle(_ text: String, with context: GameContext) {
        let data = text[6...].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        context.events.post("ol:game:parse", data: data)
    }
}
