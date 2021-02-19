//
//  CommandHandlerProcessor.swift
//  Outlander
//
//  Created by Joseph McBride on 5/3/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

protocol ICommandHandler {
    var command: String { get }

    func canHandle(_ command: String) -> Bool
    func handle(_ command: String, with: GameContext)
}

struct Command2 {
    var command: String
    var script: ScriptContext?
    var isSystemCommand: Bool = false
}

struct ScriptContext {
    var name: String
    var line: Int?
    var column: Int?
}

class CommandProcesssor {
    var handlers: [ICommandHandler] = [
        EchoCommandHandler(),
        VarCommandHandler(),
        ClassCommandHandler(),
        FlashCommandHandler(),
        BeepCommandHandler(),
        BugCommandHandler(),
        GagCommandHandler(),
    ]

    init(_ files: FileSystem) {
        handlers.append(WindowCommandHandler(files))
        handlers.append(PlayCommandHandler(files))
        handlers.append(MapperComandHandler(files))
    }

    func insertHandler(_ handler: ICommandHandler) {
        handlers.insert(handler, at: 0)
    }

    func process(_ command: String, with context: GameContext) {
        let cmd = Command2(command: command)
        process(cmd, with: context)
    }

    func process(_ command: Command2, with context: GameContext) {
        if !command.isSystemCommand {
            context.globalVars["lastcommand"] = command.command
        }

        for handler in handlers {
            if handler.canHandle(command.command) {
                handler.handle(command.command, with: context)
                return
            }
        }

        context.events.post("ol:gamecommand", data: command)
    }
}

extension ICommandHandler {
    func canHandle(_ command: String) -> Bool {
        let commands = command.split(separator: " ")
        return commands.count > 0 && String(commands[0]).lowercased() == self.command
    }
}
