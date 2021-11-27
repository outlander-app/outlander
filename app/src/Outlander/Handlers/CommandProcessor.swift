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
    var fileName: String = ""
    var preset: String = ""
}

class CommandProcesssor {
    private var handlers: [ICommandHandler] = [
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
        AliasCommandHandler(),
    ]

    private var pluginManager: OPlugin

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
        if !command.isSystemCommand {
            context.globalVars["lastcommand"] = command.command
        }

        var maybeCommand = VariableReplacer().replace(command.command, globalVars: context.globalVars)
        maybeCommand = processAliases(maybeCommand, with: context)

        maybeCommand = pluginManager.parse(input: maybeCommand)

        guard maybeCommand.count > 0 else {
            return
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
                context.events.post("ol:gamecommand", data: Command2(command: cmd, isSystemCommand: command.isSystemCommand, fileName: command.fileName, preset: command.preset))
            }
        }
    }

    func processAliases(_ input: String, with context: GameContext) -> String {
        guard context.aliases.count > 0 else {
            return input
        }

        var arguments: [String] = []
        var maybeAlias = input

        if let idx = input.index(of: " ") {
            maybeAlias = String(input[..<idx])
            let offset = input.index(idx, offsetBy: 1)
            let allArgs = String(input[offset...])
            arguments.append(allArgs)
            arguments = arguments + allArgs.argumentsSeperated()
        }

        guard let match = context.aliases.first(where: { $0.pattern == maybeAlias }) else {
            return input
        }

        var res = match.replace

        for (index, arg) in arguments.enumerated() {
            res = res.replacingOccurrences(of: "$\(index)", with: arg)
        }

        // replace any left over args in replacement pattern with empty strings
        guard let regex = RegexFactory.get("\\$\\d+") else {
            return res
        }

        res = regex.replace(res, with: "")

        return res
    }
}

extension ICommandHandler {
    func canHandle(_ command: String) -> Bool {
        let commands = command.split(separator: " ")
        return commands.count > 0 && String(commands[0]).lowercased() == self.command
    }
}
