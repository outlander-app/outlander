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
        var data = data
        for trigger in context.activeTriggers() {
            guard let matches = RegexFactory.get(trigger.pattern)?.allMatches(&data) else {
                continue
            }

            for match in matches {
                guard match.count > 0 else {
                    continue
                }

                let command = match.replace(target: trigger.action)
                context.events.sendCommand(Command2(command: command))
            }
        }
    }
}
