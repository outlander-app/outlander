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
    var isSystemCommand: Bool = false
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
        GotoComandHandler(),
        ParseCommandHandler(),
        SendCommandHandler(),
        ScriptCommandHandler(),
        ScriptRunnerCommandHandler(),
    ]

    var pluginManager: OPlugin

    init(_ files: FileSystem, pluginManager: OPlugin) {
        handlers.append(WindowCommandHandler(files))
        handlers.append(PlayCommandHandler(files))
        handlers.append(MapperComandHandler(files))

        self.pluginManager = pluginManager
    }

    func insertHandler(_ handler: ICommandHandler) {
        handlers.insert(handler, at: 0)
    }

    func process(_ command: String, with context: GameContext) {
        let cmd = Command2(command: command)
        process(cmd, with: context)
    }

    func process(_ command: Command2, with context: GameContext) {
        // TODO: replace variables

        let maybeCommand = pluginManager.parse(input: command.command)

        guard maybeCommand.count > 0 else {
            return
        }

        if !command.isSystemCommand {
            context.globalVars["lastcommand"] = maybeCommand
        }

        let cmds = maybeCommand.commandsSeperated()

        for cmd in cmds {
            var handled = false
            for handler in handlers {
                if handler.canHandle(cmd) {
                    handler.handle(cmd, with: context)
                    handled = true
                    break
                }
            }
            if !handled {
                context.events.post("ol:gamecommand", data: Command2(command: cmd, isSystemCommand: command.isSystemCommand))
            }
        }
    }
}

extension ICommandHandler {
    func canHandle(_ command: String) -> Bool {
        let commands = command.split(separator: " ")
        return commands.count > 0 && String(commands[0]).lowercased() == self.command
    }
}
