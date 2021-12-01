//
//  PresetLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 12/17/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

struct ColorPreset {
    var name: String
    var color: String
    var backgroundColor: String?
    var presetClass: String?
}

extension GameContext {
    func presetFor(_ setting: String) -> ColorPreset? {
        let settingToCheck = setting.lowercased()

        if settingToCheck.count == 0 {
            return nil
        }

        if let preset = presets[settingToCheck] {
            return preset
        }

        return nil
    }

    func addPreset(_ name: String, color: String, backgroundColor: String? = nil) {
        let preset = ColorPreset(name: name, color: color, backgroundColor: backgroundColor)
        presets[name] = preset
    }
}

class PresetLoader {
    let filename = "presets.cfg"

    let files: FileSystem

    let regex = try? Regex("^#preset \\{(.*?)\\} \\{(.*?)\\}(?:\\s\\{(.*?)\\})?$", options: [.anchorsMatchLines, .caseInsensitive])

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        context.presets.removeAll()
        setupDefaults(context)

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
            if match.count == 4 {
                let name = match.valueAt(index: 1) ?? ""

                guard name.count > 0 else {
                    continue
                }

                var color = match.valueAt(index: 2) ?? ""
                var backgroundColor = ""
                let className = match.valueAt(index: 3)

                let colors = color.components(separatedBy: ",")

                if colors.count > 1 {
                    color = colors[0].trimmingCharacters(in: CharacterSet.whitespaces)
                    backgroundColor = colors[1].trimmingCharacters(in: CharacterSet.whitespaces)
                }

                let preset = ColorPreset(name: name.lowercased(), color: color.lowercased(), backgroundColor: backgroundColor.lowercased(), presetClass: className?.lowercased())
                context.presets[name] = preset
            }
        }

        if context.presetFor("exptracker") == nil {
            context.addPreset("exptracker", color: "#66ffff")
        }
    }

    func save(_ settings: ApplicationSettings, presets: [String: ColorPreset]) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        var content = ""
        for (_, preset) in presets.sorted(by: { $0.key < $1.key }) {
            var color = preset.color
            let backgroundColor = preset.backgroundColor ?? ""
            let className = preset.presetClass ?? ""

            if backgroundColor.count > 0 {
                color = "\(color),\(backgroundColor)"
            }

            content += "#preset {\(preset.name)} {\(color.lowercased())}"

            if className.count > 0 {
                content += " {\(className)}"
            }

            content += "\n"
        }

        files.write(content, to: fileUrl)
    }

    func setupDefaults(_ context: GameContext) {
        context.addPreset("automapper", color: "#66ffff")
        context.addPreset("chatter", color: "#66ffff")
        context.addPreset("creatures", color: "#ffff00")
        context.addPreset("roomdesc", color: "#cccccc")
        context.addPreset("roomname", color: "#0000ff")
        context.addPreset("scriptecho", color: "#66ffff")
        context.addPreset("scripterror", color: "#efefef", backgroundColor: "#ff3300")
        context.addPreset("scriptinfo", color: "#0066cc")
        context.addPreset("scriptinput", color: "#acff2f")
        context.addPreset("sendinput", color: "#acff2f")
        context.addPreset("speech", color: "#66ffff")
        context.addPreset("thought", color: "#66ffff")
        context.addPreset("whisper", color: "#66ffff")
        context.addPreset("exptracker", color: "#66ffff")

        context.addPreset("roundtime", color: "#f5f5f5", backgroundColor: "#003366")
        context.addPreset("commandinput", color: "#f5f5f5", backgroundColor: "#1e1e1e")
        context.addPreset("statusbartext", color: "#f5f5f5")

        context.addPreset("health", color: "#f5f5f5", backgroundColor: "#cc0000")
        context.addPreset("mana", color: "#f5f5f5", backgroundColor: "#00004b")
        context.addPreset("stamina", color: "#f5f5f5", backgroundColor: "#004000")
        context.addPreset("concentration", color: "#f5f5f5", backgroundColor: "#009999")
        context.addPreset("spirit", color: "#f5f5f5", backgroundColor: "#400040")
    }
}
