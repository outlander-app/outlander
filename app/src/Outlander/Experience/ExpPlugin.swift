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
        var result = input
        for plugin in plugins {
            result = plugin.parse(input: result)
        }
        return result
    }

    func parse(xml: String) -> String {
        var result = xml
        for plugin in plugins {
            result = plugin.parse(xml: result)
        }
        return result
    }

    func parse(text: String) -> String {
        var result = text
        for plugin in plugins {
            result = plugin.parse(text: result)
        }
        return result
    }
}

class ExpPlugin: OPlugin {
    private var host: IHost?
    private var tracker: ExpTracker

    private var parsing = false
    private var updateWindow = false
    private var displayLearnedWithPrompt = false

    static let start_check = "Circle: "
    static let end_check = "EXP HELP for more information"

    private var textRegex: Regex
    private var foreColor = "#cccccc"

    init() {
        textRegex = RegexFactory.get("(\\w.*?):\\s+(\\d+)\\s(\\d+)%\\s(\\w.*?)\\s+\\(\\d{1,}/34\\)")!
        tracker = ExpTracker()
    }

    var name: String {
        "Experience Tracker"
    }

    func initialize(host: IHost) {
        self.host = host
    }

    func variableChanged(variable _: String, value _: String) {}

    func parse(input: String) -> String {
        let inputCheck = input.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        guard inputCheck.hasPrefix("/tracker") else {
            return input
        }

        if inputCheck.hasPrefix("/tracker report") {
            let trimmed = inputCheck[15...]
            let sorting = trimmed.toOrderBy() ?? tracker.sortingBy

            let report = tracker.buildReport(sorting: sorting)

            for cmd in report {
                host?.send(text: cmd)
            }
            return ""
        }

        switch inputCheck {
        case "/tracker reset":
            tracker.reset()
            host?.send(text: "#echo \(foreColor) \n\(name) - reset\n")
        case "/tracker update":
            updateExpWindow()
        case "/tracker display learned":
            displayLearnedWithPrompt = !displayLearnedWithPrompt
            let onOff = displayLearnedWithPrompt ? "on" : "off"
            host?.send(text: "#echo \(foreColor) \n\(name) - setting display learned to: \(onOff)\n")
        case "/tracker orderby name":
            tracker.sortingBy = .name
            updateExpWindow()
            host?.send(text: "#echo \(foreColor) \n\(name) - ordering skills by name\n")
        case "/tracker orderby name desc":
            tracker.sortingBy = .nameDesc
            updateExpWindow()
            host?.send(text: "#echo \(foreColor) \n\(name) - ordering skills by name desc\n")
        case "/tracker orderby rank":
            tracker.sortingBy = .rank
            updateExpWindow()
            host?.send(text: "#echo \(foreColor) \n\(name) - ordering skills by rank\n")
        case "/tracker orderby rank desc":
            tracker.sortingBy = .rankDesc
            updateExpWindow()
            host?.send(text: "#echo \(foreColor) \n\(name) - ordering skills by rank descending\n")
        case "/tracker orderby skillset":
            tracker.sortingBy = .skillSet
            updateExpWindow()
            host?.send(text: "#echo \(foreColor) \n\(name) - ordering skills by skillset\n")
        case "/tracker ordreby gain":
            fallthrough
        case "/tracker orderby gains":
            tracker.sortingBy = .gains
            updateExpWindow()
            host?.send(text: "#echo \(foreColor) \n\(name) - ordering skills by gains\n")
        case "/tracker ordreby gain desc":
            fallthrough
        case "/tracker orderby gains desc":
            tracker.sortingBy = .gainsDesc
            updateExpWindow()
            host?.send(text: "#echo \(foreColor) \n\(name) - ordering skills by gains desc\n")
        case "/tracker help":
            fallthrough
        default:
            let displayLearnedOnOff = displayLearnedWithPrompt ? "on" : "off"
            host?.send(text: "#echo \(foreColor) \n\(name)")
            host?.send(text: "#echo \(foreColor) Available commands:")
            host?.send(text: "#echo \(foreColor)  orderby: order skills by skillset, name, name desc, rank, rank desc, gains, gains desc. (\(tracker.sortingBy.description))")
            host?.send(text: "#echo \(foreColor)  report [orderby]:  display a report of skills with field experience or earned ranks.")
            host?.send(text: "#echo \(foreColor)  reset:   resets the tracking data.")
            host?.send(text: "#echo \(foreColor)  update:  refreshes the experience window.")
            host?.send(text: "#echo \(foreColor)  display learned: toggle display learning gains. (\(displayLearnedOnOff))")
            host?.send(text: "#echo \(foreColor)  ex:")
            host?.send(text: "#echo \(foreColor)    /tracker report rank desc")
            host?.send(text: "#echo \(foreColor)    /tracker orderby name\n")
        }

        return ""
    }

    // learning
    // <component id='exp Sorcery'><preset id='whisper'>          Sorcery:  694 85% mind lock     </preset></component>

    // pulsed
    // <roundTime value='1634753994'/><component id='exp Arcana'><preset id='whisper'>          Arcana:  1644 35% dabbling     </preset></component>

    // cleared
    // <component id='exp Sorcery'></component>

    func parse(xml: String) -> String {
        if updateWindow, xml.contains("<prompt") {
            updateExpWindow()
            updateWindow = false
            return "\(displayLearned())\(xml)"
        }

        guard let idx = xml.index(of: "<component id='exp ") else {
            return xml
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

        return xml
    }

    func parse(text: String) -> String {
        let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if text.hasPrefix("Time Development Points:") {
            let start = text.index(text.startIndex, offsetBy: 24)
            if let favorsIdx = text.index(of: "Favors") {
                let number = String(text[start ..< favorsIdx]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                tracker.tdps = Int(number) ?? 0
                self.host?.send(text: "#var tdp \(tracker.tdps)")
            }
        }

        if trimmed.hasPrefix("TDPs :") {
            let start = text.index(text.startIndex, offsetBy: 6)
            let number = String(text[start...]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            tracker.tdps = Int(number) ?? 0
            self.host?.send(text: "#var tdp \(tracker.tdps)")
        }

        if !parsing, text.hasPrefix(ExpPlugin.start_check) {
            parsing = true
            return text
        }

        if parsing, text.hasPrefix(ExpPlugin.end_check) {
            parsing = false
            updateExpWindow()
            return text
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

        return text
    }

    private func updateExpWindow() {
        let commands = tracker.buildDisplayCommands()
        for cmd in commands {
            host?.send(text: cmd)
        }
    }

    private func displayLearned() -> String {
        guard displayLearnedWithPrompt else {
            return ""
        }
        let report = tracker.buildLearnedReport()
        tracker.resetLearnedQueue()
        return report
    }
}
