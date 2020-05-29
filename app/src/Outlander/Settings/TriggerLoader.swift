//
//  TriggerLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct Trigger {
    var pattern: String
    var action: String
    var className: String
}

class TriggerLoader {
    let filename = "triggers.cfg"

    let files: FileSystem

    let regex = try? Regex("^#trigger \\{(.*?)\\} \\{(.*?)\\}(?:\\s\\{(.*?)\\})?$", options: [.anchorsMatchLines, .caseInsensitive])

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        context.triggers.removeAll()

        guard let data = files.load(fileUrl) else {
            return
        }

        guard var content = String(data: data, encoding: .utf8) else {
            return
        }

        guard let matches = regex?.allMatches(&content) else {
            return
        }

        for match in matches {
            if match.count > 2 {
                guard let pattern = match.valueAt(index: 1) else {
                    continue
                }

                let action = match.valueAt(index: 2) ?? ""
                let className = match.valueAt(index: 3) ?? ""

                context.triggers.append(
                    Trigger(pattern: pattern, action: action, className: className)
                )
            }
        }
    }

    func save(_ settings: ApplicationSettings, triggers: [Trigger]) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        var content = ""
        for trigger in triggers {
            content += "#trigger {\(trigger.pattern)} {\(trigger.action)}"

            if trigger.className.count > 0 {
                content += " {\(trigger.className)}"
            }

            content += "\n"
        }

        files.write(content, to: fileUrl)
    }
}
