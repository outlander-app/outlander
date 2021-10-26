//
//  SendCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 10/25/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class SendCommandHandler: ICommandHandler {
    var command = "#send"

    func handle(_ text: String, with context: GameContext) {
        let data = text[5...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)

        context.events.sendCommand(Command2(command: data))
    }
}
