//
//  PrintBoxCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/10/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class PrintBoxCommandHandler: ICommandHandler {
    var command = "#printbox"

    func handle(_ input: String, with context: GameContext) {
        let text = input[command.count...].trimLeadingWhitespace()

        // let lines = PrintBox.print(text, topElement: "-", sideElement: "|", cornerElement: "+", sideBoxCount: 1)
        let lines = PrintBox.print(text)

        for line in lines {
            context.events.echoText(line, preset: "scriptecho", mono: true)
        }
    }
}
