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
    var files: FileSystem

    init(context: GameContext, files: FileSystem) {
        self.context = context
        self.files = files
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

    func write(content: String, to: String) {
        let fileUrl = context.applicationSettings.paths.plugins.appendingPathComponent(to)
        files.write(content, to: fileUrl)
    }

    func append(content: String, to: String) {
        let fileUrl = context.applicationSettings.paths.plugins.appendingPathComponent(to)
        try? files.append(content, to: fileUrl)
    }

    func load(from: String) ->  String? {
        let fileUrl = context.applicationSettings.paths.plugins.appendingPathComponent(from)
        guard let data = files.load(fileUrl) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }
}
