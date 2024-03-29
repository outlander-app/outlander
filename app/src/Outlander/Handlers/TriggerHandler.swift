//
//  TriggerHandler.swift
//  Outlander
//
//  Created by Joe McBride on 11/9/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

extension GameContext {
    func activeTriggers() -> [Trigger] {
        let disabledClasses = classes.disabled()
        let rigs = triggers.filter {
            ($0.className.count == 0 || !disabledClasses.contains($0.className)) && $0.pattern.count > 0
        }
        return rigs
    }
}

class TriggerHandler: StreamHandler {
    func stream(_ data: String, with context: GameContext) {
        guard !data.isEmpty else {
            return
        }

        for trigger in context.activeTriggers() {
            guard let matches = RegexFactory.get(trigger.pattern)?.allMatches(data) else {
                continue
            }

            guard matches.count > 0 else {
                continue
            }

            var command = trigger.action

            for match in matches {
                guard match.count > 0 else {
                    continue
                }

                command = match.replace(target: command)
            }

            command = VariableReplacer().replace(command, globalVars: context.globalVars)

            context.events2.sendCommand(Command2(command: command))
        }
    }
}
