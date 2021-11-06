//
//  ExpPlugin.swift
//  Outlander
//
//  Created by Joe McBride on 11/5/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class PluginManager: OPlugin {
    private var host: IHost?
    var plugins: [OPlugin] = []

    var name: String {
        "Plugin Manager"
    }

    func initialize(host: IHost) {
        self.host = host
        for plugin in plugins {
            host.send(text: "#echo Initializing Plugin '\(plugin.name)'")
            plugin.initialize(host: host)
        }
    }

    func variableChanged(variable: String, value: String) {
        for plugin in plugins {
            plugin.variableChanged(variable: variable, value: value)
        }
    }

    func parse(input: String) -> String {
        input
//        var result = input
//        for plugin in plugins {
//            result = plugin.parse(input: result)
//        }
//        return result
    }

    func parse(xml: String) {
        for plugin in plugins {
            plugin.parse(xml: xml)
        }
    }

    func parse(text: String) {
        for plugin in plugins {
            plugin.parse(text: text)
        }
    }
}

class ExpPlugin: OPlugin {
    private var host: IHost?
    private var tracker: ExpTracker

    private var parsing = false
    private var updateWindow = false

    static let start_check = "Circle: "
    static let end_check = "EXP HELP for more information"

    private var textRegex: Regex

    init() {
        textRegex = RegexFactory.get("(\\w.*?):\\s+(\\d+)\\s(\\d+)%\\s(\\w.*?)\\s+\\(\\d{1,}/34\\)")!
        tracker = ExpTracker()
    }

    var name: String {
        "Experience"
    }

    func initialize(host: IHost) {
        self.host = host
    }

    func variableChanged(variable _: String, value _: String) {}

    func parse(input: String) -> String {
        input
    }

    // learning
    // <component id='exp Sorcery'><preset id='whisper'>          Sorcery:  694 85% mind lock     </preset></component>

    // pulsed
    // <roundTime value='1634753994'/><component id='exp Arcana'><preset id='whisper'>          Arcana:  1644 35% dabbling     </preset></component>

    // cleared
    // <component id='exp Sorcery'></component>

    func parse(xml: String) {
        if updateWindow, xml.contains("<prompt") {
            updateExpWindow()
            updateWindow = false
            return
        }

        guard let idx = xml.index(of: "<component id='exp ") else {
            return
        }

        var copy = String(xml[idx...])

        let regex = RegexFactory.get(".+>\\s*(.+):\\s+(\\d+)\\s(\\d+)%\\s([\\w\\s]+)<.*")!
        if let match = regex.firstMatch(&copy) {
            let isNew = xml.contains("<preset id='whisper'>")

            let name = match.valueAt(index: 1)?.replacingOccurrences(of: " ", with: "_") ?? ""
            let learningRateName = match.valueAt(index: 4)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? "clear"
            let learningRate = learningRateLookup[learningRateName] ?? .clear
            let ranks = Double("\(match.valueAt(index: 2) ?? "0").\(match.valueAt(index: 3) ?? "0")") ?? 0

            tracker.update(SkillExp(name: name, mindState: learningRate, ranks: ranks, isNew: isNew))

            host?.set(variable: "\(name).Ranks", value: "\(ranks)")
            host?.set(variable: "\(name).LearningRate", value: "\(learningRate.rawValue)")
            host?.set(variable: "\(name).LearningRateName", value: "\(learningRate.description)")

            updateWindow = true
        } else {
            // handle empty tag
            let regex = RegexFactory.get("id='exp\\s([\\w\\s]+)'")
            if let match = regex?.firstMatch(&copy) {
                let name = match.valueAt(index: 1)?.replacingOccurrences(of: " ", with: "_") ?? ""
                let learningRate = LearningRate.clear

                tracker.update(SkillExp(name: name, mindState: learningRate, ranks: 0, isNew: false))

                host?.set(variable: "\(name).Ranks", value: "0.0")
                host?.set(variable: "\(name).LearningRate", value: "\(learningRate.rawValue)")
                host?.set(variable: "\(name).LearningRateName", value: "\(learningRate.description)")

                updateWindow = true
            }
        }
    }

    func parse(text: String) {
        if !parsing, text.hasPrefix(ExpPlugin.start_check) {
            parsing = true
            return
        }

        if parsing, text.hasPrefix(ExpPlugin.end_check) {
            parsing = false
            updateExpWindow()
            return
        }

        var copy = text
        let matches = textRegex.allMatches(&copy)

        for match in matches {
            let name = match.valueAt(index: 1)?.replacingOccurrences(of: " ", with: "_") ?? ""
            let learningRate = learningRateLookup[match.valueAt(index: 4) ?? "0"] ?? .clear
            let ranks = Double("\(match.valueAt(index: 2) ?? "0").\(match.valueAt(index: 3) ?? "0")") ?? 0

            tracker.update(SkillExp(name: name, mindState: learningRate, ranks: ranks, isNew: false))

            host?.set(variable: "\(name).Ranks", value: "\(ranks)")
            host?.set(variable: "\(name).LearningRate", value: "\(learningRate.rawValue)")
            host?.set(variable: "\(name).LearningRateName", value: "\(learningRate.description)")
        }
    }

    private func updateExpWindow() {
        let commands = tracker.buildDisplayCommands()
        for cmd in commands {
            host?.send(text: cmd)
        }
    }
}
