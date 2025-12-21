//
//  ExpPlugin.swift
//  Outlander
//
//  Created by Joe McBride on 11/5/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import Plugins

class ExpPlugin: OPlugin {
    private var host: IHost?
    private var tracker: ExpTracker

    private var parsing = false
    private var updateWindow = false
    private var displayLearnedWithPrompt = false

    static let start_check = "Circle: "
    static let end_check = "EXP HELP for more information"

    private var textRegex: Regex

    required init() {
        textRegex = RegexFactory.get("(\\w.*?):\\s+(\\d+)\\s(\\d+)%\\s(\\w.*?)\\s+\\(\\d{1,}/34\\)")!
        tracker = ExpTracker()
    }

    var name: String {
        "Experience Tracker"
    }

    func initialize(host: IHost) {
        self.host = host

        tracker.clear()

        // load any existing exp from variables
        for skill in tracker.skillSets {
            let ranksStr = host.get(variable: "\(skill).Ranks")

            // print("\(skill): \(ranksStr) ", terminator: "")

            if ranksStr.isEmpty {
                // print("")
                continue
            }

            let ranks = Double(ranksStr) ?? 0
            let learningRateStr = host.get(variable: "\(skill).LearningRateName")
            let learningRate = learningRateLookup[learningRateStr] ?? .clear

            // print("\(learningRate.description)")

            let exp = SkillExp(name: skill, mindState: learningRate, ranks: Double(ranks), isNew: false)
            tracker.update(exp)
        }

        displayLearnedWithPrompt = host.get(variable: "exptracker:displaylearned").toBool() == true
    }

    func variableChanged(variable _: String, value _: String) {}

    func parse(input: String) -> String {
        let inputCheck = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard inputCheck.hasPrefix("/tracker") else {
            return input
        }

        let foreColor = host?.get(preset: "exptracker:text") ?? ""
        let learnedColor = host?.get(preset: "exptracker:learned") ?? ""

        if inputCheck.hasPrefix("/tracker report") {
            let trimmed = inputCheck[15...]
            let sorting = trimmed.toOrderBy() ?? tracker.sortingBy
            let rexp = host?.get(variable: "rexp") ?? ""
            let favor = host?.get(variable: "favor") ?? ""
            let sleep = host?.get(variable: "sleep") ?? ""
            let tdps = host?.get(variable: "tdp") ?? ""

            let report = tracker.buildReport(sorting: sorting, foreColor: foreColor, learnedColor: learnedColor, favors: favor, rexp: rexp, sleep: sleep, tdps: tdps)

            for cmd in report {
                host?.send(text: cmd)
            }
            return ""
        }

        if inputCheck.hasPrefix("/tracker lowest") {
            guard let (idx, lowest) = getLowestSkill(String(inputCheck.dropFirst(15)).trimmingCharacters(in: .whitespacesAndNewlines)) else {
                host?.send(text: "#echo sending NONE")
                host?.send(text: "#parse EXPTRACKER NONE -1")
                return ""
            }

            host?.send(text: "#parse EXPTRACKER \(lowest.name) \(idx)")

            return ""
        }

        if inputCheck.hasPrefix("/tracker highest") {
            guard let (idx, highest) = getHighestSkill(String(inputCheck.dropFirst(16)).trimmingCharacters(in: .whitespacesAndNewlines)) else {
                host?.send(text: "#parse EXPTRACKER NONE -1")
                return ""
            }

            host?.send(text: "#parse EXPTRACKER \(highest.name) \(idx)")
            return ""
        }

        switch inputCheck {
        case "/tracker reset":
            tracker.reset()
            host?.send(text: "#echo \(foreColor) \n\(name) - reset\n")
        case "/tracker update":
            updateExpWindow()
        case "/tracker display learned":
            tracker.resetLearnedQueue()
            displayLearnedWithPrompt = !displayLearnedWithPrompt
            let onOff = displayLearnedWithPrompt ? "on" : "off"
            host?.set(variable: "exptracker:displaylearned", value: onOff)
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
            host?.send(text: "#echo \(foreColor)  display learned: toggle display mindstate gains/losses. (\(displayLearnedOnOff))")
            host?.send(text: "#echo \(foreColor)  lowest: calculate the lowest mindstate or rank for a list of skills. (Athletics|Thievery)")
            host?.send(text: "#echo \(foreColor)  highest: calculate the highest mindstate or rank for a list of skills. (Bow|Locksmithing)")
            host?.send(text: "#echo \(foreColor)  ex:")
            host?.send(text: "#echo \(foreColor)    /tracker report rank desc")
            host?.send(text: "#echo \(foreColor)    /tracker orderby name")
            host?.send(text: "#echo \(foreColor)    /tracker lowest Athletics|Locksmithing\n")
        }

        return ""
    }

    // learning
    // <component id='exp Sorcery'><preset id='whisper'>          Sorcery:  694 85% mind lock     </preset></component>

    // pulsed
    // <roundTime value='1634753994'/><component id='exp Arcana'><preset id='whisper'>          Arcana:  1644 35% dabbling     </preset></component>

    // cleared
    // <component id='exp Sorcery'></component>

    // <component id='exp rexp'>Rested EXP Stored: 5:59 hours  Usable This Cycle: 5:53 hours  Cycle Refreshes: 22:32 hours</component>
    // <component id='exp tdp'>            TDPs:  926</component>
    // <component id='exp favor'>          Favors:  12</component>
    // <component id='exp sleep'></component>

    func parse(xml: String) -> String {
        if updateWindow, xml.contains("<prompt") {
            updateExpWindow()
            updateWindow = false
            return "\(displayLearned())\(xml)"
        }

        guard let idx = xml.index(of: "<component id='exp ") else {
            return xml
        }

        if xml.contains("<d cmd=") {
            parseExpBrief(idx: idx, xml: xml)
        } else {
            parseExpNormal(idx: idx, xml: xml)
        }

        return xml
    }

    func parse(text: String, window: String) -> String {
        guard window.lowercased() == "main" || window.isEmpty else {
            return text
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return text
        }

        if trimmed.hasPrefix("Time Development Points:") {
            let start = trimmed.index(trimmed.startIndex, offsetBy: 24)
            if let favorsIdx = trimmed.index(of: "Favors") {
                let number = String(trimmed[start ..< favorsIdx]).trimmingCharacters(in: .whitespacesAndNewlines)
                host?.send(text: "#var tdp \(number)")
            }
        }

        if trimmed.hasPrefix("TDPs :") {
            let start = trimmed.index(trimmed.startIndex, offsetBy: 6)
            let number = String(trimmed[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
            host?.send(text: "#var tdp \(number)")
        }

        if !parsing, trimmed.hasPrefix(ExpPlugin.start_check) {
            parsing = true
            return text
        }

        if parsing, trimmed.hasPrefix(ExpPlugin.end_check) {
            parsing = false
            updateExpWindow()
            return text
        }

//        var copy = trimmed
        let matches = textRegex.allMatches(trimmed)

        for match in matches {
            let name = match.valueAt(index: 1)?.replacingOccurrences(of: " ", with: "_") ?? ""
            let learningRate = learningRateLookup[match.valueAt(index: 4) ?? "0"] ?? .clear
            let ranks = Double("\(match.valueAt(index: 2) ?? "0").\(match.valueAt(index: 3) ?? "0")") ?? 0

            tracker.update(SkillExp(name: name, mindState: learningRate, ranks: ranks, isNew: false), trackLearned: displayLearnedWithPrompt)

            host?.set(variable: "\(name).Ranks", value: "\(ranks)")
            host?.set(variable: "\(name).LearningRate", value: "\(learningRate.rawValue)")
            host?.set(variable: "\(name).LearningRateName", value: "\(learningRate.description)")
        }

        return text
    }

    private func parseExpNormal(idx: String.Index, xml: String) {
        var copy = String(xml[idx...])

        let regex = RegexFactory.get(".+>\\s*(.+):\\s+(\\d+)\\s(\\d+)%\\s([\\w\\s]+)<.*")!
        if let match = regex.firstMatch(&copy) {
            let isNew = xml.contains("<preset id='whisper'>")

            let name = match.valueAt(index: 1)?.replacingOccurrences(of: " ", with: "_") ?? ""
            let learningRateName = match.valueAt(index: 4)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "clear"
            let learningRate = learningRateLookup[learningRateName] ?? .clear
            let ranks = Double("\(match.valueAt(index: 2) ?? "0").\(match.valueAt(index: 3) ?? "0")") ?? 0

            tracker.update(SkillExp(name: name, mindState: learningRate, ranks: ranks, isNew: isNew), trackLearned: displayLearnedWithPrompt)

            host?.set(variable: "\(name).Ranks", value: String(format: "%.2f", ranks))
            host?.set(variable: "\(name).LearningRate", value: "\(learningRate.rawValue)")
            host?.set(variable: "\(name).LearningRateName", value: "\(learningRate.description)")

            updateWindow = true
        } else {
            // handle additional tags
            let regex = RegexFactory.get("id='exp\\s([\\w\\s]+)'")
            if let match = regex?.firstMatch(&copy) {
                let name = match.valueAt(index: 1)?.replacingOccurrences(of: " ", with: "_") ?? ""

                switch name {
                case "favor":
                    let valReg = RegexFactory.get(".+>\\s*(.+)<.*")
                    if let match = valReg?.firstMatch(&copy) {
                        let txt = match.valueAt(index: 1) ?? ""
                        let value = Int(txt.replacingOccurrences(of: "Favors:", with: "").trimLeadingWhitespace()) ?? 0
                        host?.set(variable: name, value: "\(value)")
                    }
                    break
                case "rexp":
                    let valReg = RegexFactory.get(".+>\\s*(.+)<.*")
                    if let match = valReg?.firstMatch(&copy) {
                        let txt = match.valueAt(index: 1) ?? ""
                        host?.set(variable: name, value: txt)
                    } else {
                        host?.set(variable: name, value: "")
                    }
                    break
                case "sleep":
                    let valReg = RegexFactory.get(".+>\\s*(.+)<.*")
                    if let match = valReg?.firstMatch(&copy) {
                        let txt = (match.valueAt(index: 1) ?? "").replacingOccurrences(of: "</b>", with: "")
                        host?.set(variable: name, value: txt)
                    } else {
                        host?.set(variable: name, value: "")
                    }
                    break
                case "tdp":
                    let valReg = RegexFactory.get(".+>\\s*(.+)<.*")
                    if let match = valReg?.firstMatch(&copy) {
                        let txt = match.valueAt(index: 1) ?? ""
                        let value = Int(txt.replacingOccurrences(of: "TDPs:", with: "").trimLeadingWhitespace()) ?? 0
                        host?.set(variable: name, value: "\(value)")
                    }
                    break
                default:
                    let learningRate = LearningRate.clear

                    tracker.update(SkillExp(name: name, mindState: learningRate, ranks: 0, isNew: false), trackLearned: displayLearnedWithPrompt)

                    host?.set(variable: "\(name).Ranks", value: "0.0")
                    host?.set(variable: "\(name).LearningRate", value: "\(learningRate.rawValue)")
                    host?.set(variable: "\(name).LearningRateName", value: "\(learningRate.description)")
                }

                updateWindow = true
            }
        }
    }

    private func parseExpBrief(idx: String.Index, xml: String) {
        var copy = String(xml[idx...])

        let regex = RegexFactory.get("cmd='skill\\s(.+)'>.+:\\s+(\\d+)\\s(\\d+)%\\s+\\[\\s?(\\d+)?.*")!
        if let match = regex.firstMatch(&copy) {
            let isNew = xml.contains("<preset id='whisper'>")

            let name = match.valueAt(index: 1)?.replacingOccurrences(of: " ", with: "_") ?? ""
            let learningRateStr = match.valueAt(index: 4)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
            let learningRate = LearningRate(rawValue: Int(learningRateStr) ?? 0) ?? .clear
            let ranks = Double("\(match.valueAt(index: 2) ?? "0").\(match.valueAt(index: 3) ?? "0")") ?? 0

            tracker.update(SkillExp(name: name, mindState: learningRate, ranks: ranks, isNew: isNew), trackLearned: displayLearnedWithPrompt)

            host?.set(variable: "\(name).Ranks", value: String(format: "%.2f", ranks))
            host?.set(variable: "\(name).LearningRate", value: "\(learningRate.rawValue)")
            host?.set(variable: "\(name).LearningRateName", value: "\(learningRate.description)")

            updateWindow = true
        } else {
            // handle additional tags
            let regex = RegexFactory.get("id='exp\\s([\\w\\s]+)'")
            if let match = regex?.firstMatch(&copy) {
                let name = match.valueAt(index: 1)?.replacingOccurrences(of: " ", with: "_") ?? ""
                
                switch name {
                case "favor":
                    let valReg = RegexFactory.get(".+>\\s*(.+)<.*")
                    if let match = valReg?.firstMatch(&copy) {
                        let txt = match.valueAt(index: 1) ?? ""
                        let value = Int(txt.replacingOccurrences(of: "Favors:", with: "").trimLeadingWhitespace()) ?? 0
                        host?.set(variable: name, value: "\(value)")
                    }
                    break
                case "rexp":
                    let valReg = RegexFactory.get(".+>\\s*(.+)<.*")
                    if let match = valReg?.firstMatch(&copy) {
                        let txt = match.valueAt(index: 1) ?? ""
                        host?.set(variable: name, value: txt)
                    } else {
                        host?.set(variable: name, value: "")
                    }
                    break
                case "sleep":
                    let valReg = RegexFactory.get(".+>\\s*(.+)<.*")
                    if let match = valReg?.firstMatch(&copy) {
                        let txt = (match.valueAt(index: 1) ?? "").replacingOccurrences(of: "</b>", with: "")
                        host?.set(variable: name, value: txt)
                    } else {
                        host?.set(variable: name, value: "")
                    }
                    break
                case "tdp":
                    let valReg = RegexFactory.get(".+>\\s*(.+)<.*")
                    if let match = valReg?.firstMatch(&copy) {
                        let txt = match.valueAt(index: 1) ?? ""
                        let value = Int(txt.replacingOccurrences(of: "TDPs:", with: "").trimLeadingWhitespace()) ?? 0
                        host?.set(variable: name, value: "\(value)")
                    }
                    break
                default:
                    let learningRate = LearningRate.clear
                    
                    tracker.update(SkillExp(name: name, mindState: learningRate, ranks: 0, isNew: false), trackLearned: displayLearnedWithPrompt)

                    host?.set(variable: "\(name).Ranks", value: "0.0")
                    host?.set(variable: "\(name).LearningRate", value: "\(learningRate.rawValue)")
                    host?.set(variable: "\(name).LearningRateName", value: "\(learningRate.description)")
                }

                updateWindow = true
            }
        }
    }

    private func updateExpWindow() {
        let foreColor = host?.get(preset: "exptracker:text") ?? ""
        let learnedColor = host?.get(preset: "exptracker:learned") ?? ""
        let rexp = host?.get(variable: "rexp") ?? ""
        let favor = host?.get(variable: "favor") ?? ""
        let sleep = host?.get(variable: "sleep") ?? ""
        let tdps = host?.get(variable: "tdp") ?? ""

        let commands = tracker.buildDisplayCommands(foreColor: foreColor, learnedColor: learnedColor, favors: favor, rexp: rexp, sleep: sleep, tdps: tdps)
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

    func getLowestSkill(_ maybeSkills: String) -> (Int, SkillExp)? {
        let skills = maybeSkills.components(separatedBy: CharacterSet([" ", "|", ","]))
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var found: SkillExp?
        var foundIdx = -1

        for (index, skill) in skills.enumerated() {
            guard let exp = tracker.find(skill) else {
                continue
            }

            // choose if lower mindstate
            if found == nil || exp.mindState < found!.mindState {
                found = exp
                foundIdx = index
                // choose if mindstate equal and lower ranks
            } else if found != nil, exp.mindState == found!.mindState, exp.ranks < found!.ranks {
                found = exp
                foundIdx = index
            }
        }

        guard foundIdx > -1, found != nil else {
            return nil
        }

        return (foundIdx, found!)
    }

    func getHighestSkill(_ maybeSkills: String) -> (Int, SkillExp)? {
        let skills = maybeSkills.components(separatedBy: CharacterSet([" ", "|", ","]))
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var found: SkillExp?
        var foundIdx = -1

        for (index, skill) in skills.enumerated() {
            guard let exp = tracker.find(skill) else {
                continue
            }

            // choose if higher mindstate
            if found == nil || exp.mindState > found!.mindState {
                found = exp
                foundIdx = index
                // choose if mindstate equal and higher ranks
            } else if found != nil, exp.mindState == found!.mindState, exp.ranks > found!.ranks {
                found = exp
                foundIdx = index
            }
        }

        guard foundIdx > -1, found != nil else {
            return nil
        }

        return (foundIdx, found!)
    }
}
