//
//  BeepCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation
import AppKit

class BeepCommandHandler : ICommandHandler {
    
    var command = "#beep"
    
    func handle(command: String, withContext: GameContext) {
        NSSound.beep()
    }
}

class FlashCommandHandler : ICommandHandler {
    
    var command = "#flash"
    
    func handle(command: String, withContext: GameContext) {
        NSApplication.shared.requestUserAttention(.criticalRequest)
    }
}

class BugCommandHandler : ICommandHandler {
    
    var command = "#bug"

    func handle(command: String, withContext: GameContext) {
        NSWorkspace.shared.open(URL(string: "https://github.com/joemcbride/outlander-osx/issues/new")!)
    }
}
