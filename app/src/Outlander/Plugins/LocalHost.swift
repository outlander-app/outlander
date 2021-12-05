//
//  LocalHost.swift
//  Outlander
//
//  Created by Joe McBride on 12/4/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import Plugins

class LocalHost: IHost {
    var context: GameContext

    init(context: GameContext) {
        self.context = context
    }

    func send(text: String) {
        context.events.sendCommand(Command2(command: text, isSystemCommand: true))
    }

    func get(variable: String) -> String {
        context.globalVars[variable] ?? ""
    }

    func set(variable: String, value: String) {
        context.globalVars[variable] = value
    }

    func get(preset: String) -> String? {
        guard let preset = context.presetFor(preset) else {
            return nil
        }

        var color = preset.color
        if let bg = preset.backgroundColor, !bg.isEmpty {
            color = "\(color),\(bg)"
        }
        return color
    }
}
