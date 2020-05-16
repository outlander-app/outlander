//
//  CommandHandlerProcessor.swift
//  Outlander
//
//  Created by Joseph McBride on 5/3/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class CommandHandlerProcesssor {

    var handlers: [ICommandHandler] = [
        EchoCommandHandler(),
        VarCommandHandler(),
        ClassCommandHandler(),
        WindowCommandHandler(),
        FlashCommandHandler(),
        BeepCommandHandler(),
        BugCommandHandler()
    ]

    init(_ files: FileSystem) {
        handlers.append(PlayCommandHandler(files))
    }

    func handled(command:String, withContext: GameContext) -> Bool {
        
        for handler in self.handlers {
            if handler.canHandle(command: command) {
                handler.handle(command: command, withContext: withContext)
                return true
            }
        }
        
        return false
    }
}

protocol ICommandHandler {
    var command: String { get }
    
    func canHandle(command: String) -> Bool
    func handle(command: String, withContext: GameContext)
}

extension ICommandHandler {
    func canHandle(command: String) -> Bool {
        let commands = command.split(separator: " ")
        return commands.count > 0 && String(commands[0]).lowercased() == self.command
    }
}
