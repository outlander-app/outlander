//
//  VariablesLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class VariablesLoader {
    let filename = "variables.cfg"

    let files: FileSystem

    let regex = try? Regex("^#var \\{(.*)\\} \\{(.*)\\}$", options: [.anchorsMatchLines, .caseInsensitive])

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        guard let data = files.load(fileUrl) else {
            return
        }

        guard let content = String(data: data, encoding: .utf8) else {
            return
        }

        guard let matches = regex?.allMatches(content) else {
            return
        }

        context.globalVars.removeAll()
        setDefaults(context)

        for match in matches {
            if match.count > 1 {
                guard let key = match.valueAt(index: 1) else {
                    continue
                }

                let value = match.valueAt(index: 2) ?? ""
                context.globalVars[key] = value
            }
        }

        context.globalVars["roundtime"] = "0"
    }

    func save(_ settings: ApplicationSettings, variables: Variables) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        var content = ""
        for (key, value) in variables.sorted() {
            content += "#var {\(key)} {\(value)}\n"
        }

        files.write(content, to: fileUrl)
    }

    func setDefaults(_ context: GameContext) {
        context.globalVars["prompt"] = ">"
        context.globalVars["lefthand"] = "Empty"
        context.globalVars["righthand"] = "Empty"
        context.globalVars["preparedspell"] = "None"
        context.globalVars["tdp"] = "0"
    }
}
