//
//  ExpTracker.swift
//  Outlander
//
//  Created by Joe McBride on 11/4/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

extension String {
    func leftPadding(toLength: Int, withPad character: Character = " ") -> String {
        let stringLength = count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(suffix(toLength))
        }
    }

    func rightPadding(toLength: Int, withPad character: Character = " ") -> String {
        let stringLength = count
        if stringLength < toLength {
            return self + String(repeatElement(character, count: toLength - stringLength))
        } else {
            return String(suffix(toLength))
        }
    }
}

class SkillExp: CustomStringConvertible {
    var name: String = ""
    var mindState: LearningRate = .clear
    var ranks: Double = 0
    var originalRanks: Double = 0
    var isNew: Bool = false

    init() {}

    init(name: String, mindState: LearningRate, ranks: Double, isNew: Bool) {
        self.name = name
        self.mindState = mindState
        self.ranks = ranks
        originalRanks = ranks
        self.isNew = isNew
    }

    var earnedRanks: Double { ranks - originalRanks }

    var description: String {
        let state = "(\(mindState.rawValue)/34)"
        var sign = earnedRanks > 0 ? "+" : "-"
        if earnedRanks == 0 {
            sign = " "
        }

        let diffStr = String(format: "%@%0.2f", sign, abs(earnedRanks))
        let percent = ranks.truncatingRemainder(dividingBy: 1) * 100

        let rankName = name.replacingOccurrences(of: "_", with: " ").leftPadding(toLength: 16)

        return String(format: "%@: %4d %02.0f%%  %@ %@", rankName, Int(ranks), percent, state.leftPadding(toLength: 7), diffStr)
    }
}

struct ExpLearned {
    var name: String
    var learned: Double
    var mindState: Int

    var learnedRanksDescription: String {
        var sign = learned > 0 ? "+" : "-"
        if learned == 0 {
            sign = " "
        }

        return String(format: "%@ %@%0.2f", name, sign, abs(learned))
    }

    var learnedMindstateDescription: String {
        var sign = mindState > 0 ? "+" : "-"
        if mindState == 0 {
            sign = ""
        }

        let display: Double = abs(Double(mindState))

        return "\(name) \(sign)\(Int(display))"
    }
}

class ExpTracker {
    var skills: [String: SkillExp] = [:]
    var startOfTracking: Date?
    var sortingBy: OrderBy = .skillSet

    var learnedQueue: [ExpLearned] = []

    var skillSets: [String]

    static var dateFormatter = DateFormatter()

    enum OrderBy: CustomStringConvertible {
        case name
        case nameDesc
        case skillSet
        case rank
        case rankDesc
        case gains
        case gainsDesc

        var description: String {
            switch self {
            case .name:
                return "name"
            case .nameDesc:
                return "name desc"
            case .skillSet:
                return "skillset"
            case .rank:
                return "rank"
            case .rankDesc:
                return "rank desc"
            case .gains:
                return "gains"
            case .gainsDesc:
                return "gains desc"
            }
        }
    }

    init() {
        ExpTracker.dateFormatter.dateFormat = "hh:mm:ss a"

        skillSets = ["Shield_Usage", "Light_Armor", "Chain_Armor", "Brigandine", "Plate_Armor", "Defending", "Parry_Ability", "Small_Edged", "Large_Edged", "Twohanded_Edged", "Small_Blunt", "Large_Blunt", "Twohanded_Blunt", "Slings", "Bow", "Crossbow", "Staves", "Polearms", "Light_Thrown", "Heavy_Thrown", "Brawling", "Offhand_Weapon", "Melee_Mastery", "Missile_Mastery", "Expertise", "Elemental_Magic", "Holy_Magic", "Inner_Fire", "Inner_Magic", "Life_Magic", "Arcane_Magic", "Attunement", "Arcana", "Targeted_Magic", "Augmentation", "Debilitation", "Utility", "Warding", "Sorcery", "Theurgy", "Astrology", "Summoning", "Conviction", "Evasion", "Athletics", "Perception", "Stealth", "Locksmithing", "Thievery", "First_Aid", "Outdoorsmanship", "Skinning", "Scouting", "Instinct", "Backstab", "Thanatology", "Forging", "Engineering", "Outfitting", "Alchemy", "Enchanting", "Scholarship", "Mechanical_Lore", "Appraisal", "Performance", "Tactics", "Bardic_Lore", "Empathy", "Trading"]
    }

    func find(_ skillName: String) -> SkillExp? {
        skills.values.first(where: { $0.name.lowercased() == skillName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased() })
    }

    func resetLearnedQueue() {
        learnedQueue = []
    }

    func clear() {
        skills.removeAll()
        startOfTracking = nil
    }

    func reset() {
        for skill in skills.values {
            skill.originalRanks = skill.ranks
            skill.isNew = false
        }

        startOfTracking = Date()
    }

    func update(_ exp: SkillExp, trackLearned: Bool = false) {
        if startOfTracking == nil {
            startOfTracking = Date()
        }

        var skill = skills[exp.name]

        if skill == nil {
            skill = exp
            skill?.originalRanks = exp.ranks
            skills[exp.name] = skill
        }

        skill?.ranks = exp.ranks == 0 ? skill?.ranks ?? 0 : exp.ranks

        if skill?.originalRanks == 0 {
            skill?.originalRanks = skill?.ranks ?? 0
        }

        if trackLearned {
            let learnedMindState: Int = exp.mindState.rawValue - (skill?.mindState.rawValue ?? 0)
            // track only positive gained minstate
            if learnedMindState > 0 {
                learnedQueue.append(ExpLearned(name: exp.name, learned: 0, mindState: learnedMindState))
            }
        }

        skill?.isNew = exp.isNew
        skill?.mindState = exp.mindState
    }

    func skillsWithMindstate() -> [SkillExp] {
        let result = skills.values.filter {
            $0.mindState.rawValue > 0
        }
        return sort(result)
    }

    func skillsWithMindstateOrGain() -> [SkillExp] {
        skillsWithMindstateOrGain(sorting: sortingBy)
    }

    func skillsWithMindstateOrGain(sorting: OrderBy) -> [SkillExp] {
        let result = skills.values.filter {
            $0.mindState.rawValue > 0 || $0.earnedRanks > 0
        }
        return sort(result, by: sorting)
    }

    func sort(_ skills: [SkillExp]) -> [SkillExp] {
        sort(skills, by: sortingBy)
    }

    func sort(_ skills: [SkillExp], by: OrderBy) -> [SkillExp] {
        switch by {
        case .skillSet:
            return skills.sorted(by: { a, b in
                let idxA = skillSets.firstIndex(of: a.name) ?? 0
                let idxB = skillSets.firstIndex(of: b.name) ?? 0
                return idxA < idxB
            })
        case .rank:
            return skills.sorted(by: { $0.ranks < $1.ranks })
        case .rankDesc:
            return skills.sorted(by: { $0.ranks > $1.ranks })
        case .name:
            return skills.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        case .nameDesc:
            return skills.sorted(by: { $0.name.lowercased() > $1.name.lowercased() })
        case .gains:
            return skills.sorted(by: { $0.earnedRanks < $1.earnedRanks })
        case .gainsDesc:
            return skills.sorted(by: { $0.earnedRanks > $1.earnedRanks })
        }
    }

    func buildDisplayCommands(foreColor: String, learnedColor: String, favors: String, rexp: String, sleep: String, tdps: String) -> [String] {
        var tags: [String] = []

        for skill in skillsWithMindstate() {
            let fontColor = skill.isNew ? learnedColor : foreColor
            let tag = "\(fontColor)\(skill.description)"
            tags.append(tag)
        }

        if startOfTracking == nil {
            startOfTracking = Date()
        }

        let diff = Date().timeIntervalSince(startOfTracking!)
        if !sleep.isEmpty {
            tags.append("\(foreColor) \n\(sleep)")
        }

        tags.append("\(foreColor) \nTDPs: \(tdps)")
        tags.append("\(foreColor) Favors: \(favors)")

        if !rexp.isEmpty {
            tags.append("\(foreColor) \(rexp)")
        }

        tags.append("\(foreColor) Tracking for: \(diff.formatted)")
        tags.append("\(foreColor) Last updated: \(ExpTracker.dateFormatter.string(from: Date()))")

        return ["#echo >experience @suspend@"] + tags.map {
            "#echo >experience \($0)"
        } + ["#echo >experience @resume@"]
    }

    func buildReport(sorting: OrderBy, foreColor: String, learnedColor: String, favors: String, rexp: String, sleep: String, tdps: String) -> [String] {
        var tags: [String] = ["\(foreColor) \nExperience Tracker", "\(foreColor) Showing all skills with field experience or earned ranks.\n"]

        for skill in skillsWithMindstateOrGain(sorting: sorting) {
            let fontColor = skill.isNew ? learnedColor : foreColor
            let tag = "\(fontColor) \(skill.description)"
            tags.append(tag)
        }

        if startOfTracking == nil {
            startOfTracking = Date()
        }

        let diff = Date().timeIntervalSince(startOfTracking!)

        if !sleep.isEmpty {
            tags.append("\(foreColor) \n\(sleep)")
        }

        tags.append("\(foreColor) \nTDPs: \(tdps)")
        tags.append("\(foreColor) Favors: \(favors)")

        if !rexp.isEmpty {
            tags.append("\(foreColor) \(rexp)")
        }

        tags.append("\(foreColor) Tracking for: \(diff.formatted)")
        tags.append("\(foreColor) Last updated: \(ExpTracker.dateFormatter.string(from: Date()))\n")

        return tags.map {
            "#echo \($0)"
        }
    }

    func buildLearnedReport() -> String {
        let learned = (learnedQueue.map(\.learnedMindstateDescription)).joined(separator: ", ")

        guard learned.count > 0 else {
            return ""
        }

        return "<pushstream id='exptracker'/><preset id='exptracker:pulse'>Learned: \(learned)\n</preset><popstream/>"
    }
}

let orderByLookup: [String: ExpTracker.OrderBy] = [
    "skillset": .skillSet,
    "name": .name,
    "name desc": .nameDesc,
    "rank": .rank,
    "ranks": .rank,
    "rank desc": .rankDesc,
    "ranks desc": .rankDesc,
    "gains": .gains,
    "gains desc": .gainsDesc,
]

extension String {
    func toOrderBy() -> ExpTracker.OrderBy? {
        orderByLookup[trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }
}
