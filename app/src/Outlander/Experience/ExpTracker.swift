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

class ExpTracker {
    var skills: [String: SkillExp] = [:]
    var startOfTracking: Date?
    var orderBy: String = ""

    var skillSets: [String]

    static var dateFormatter = DateFormatter()

    init() {
        ExpTracker.dateFormatter.dateFormat = "hh:mm:ss a"

        skillSets = ["Shield_Usage", "Light_Armor", "Chain_Armor", "Brigandine", "Plate_Armor", "Defending", "Parry_Ability", "Small_Edged", "Large_Edged", "Twohanded_Edged", "Small_Blunt", "Large_Blunt", "Twohanded_Blunt", "Slings", "Bow", "Crossbow", "Staves", "Polearms", "Light_Thrown", "Heavy_Thrown", "Brawling", "Offhand_Weapon", "Melee_Mastery", "Missile_Mastery", "Expertise", "Elemental_Magic", "Holy_Magic", "Inner_Fire", "Inner_Magic", "Life_Magic", "Arcane_Magic", "Attunement", "Arcana", "Targeted_Magic", "Augmentation", "Debilitation", "Utility", "Warding", "Sorcery", "Theurgy", "Astrology", "Summoning", "Conviction", "Evasion", "Athletics", "Perception", "Stealth", "Locksmithing", "Thievery", "First_Aid", "Outdoorsmanship", "Skinning", "Scouting", "Backstab", "Thantology", "Forging", "Engineering", "Outfitting", "Alchemy", "Enchanting", "Scholarship", "Mechanical_Lore", "Appraisal", "Performance", "Tactics", "Bardic_Lore", "Empathy", "Trading"]
    }

    func reset() {
        for skill in skills.values {
            skill.originalRanks = skill.ranks
            skill.isNew = false
        }

        startOfTracking = Date()
    }

    func update(_ exp: SkillExp) {
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

        skill?.isNew = exp.isNew
        skill?.mindState = exp.mindState
    }

    func skillsWithMindstate() -> [SkillExp] {
        let result = skills.values.filter {
            $0.mindState.rawValue > 0
        }
        return sort(result)
    }

    func sort(_ skills: [SkillExp]) -> [SkillExp] {
        skills.sorted(by: { a, b in
            let idxA = skillSets.firstIndex(of: a.name) ?? 0
            let idxB = skillSets.firstIndex(of: b.name) ?? 0

            return idxA < idxB
        })
//        return skills.sorted(by: { $0.name < $1.name })
    }

    func buildDisplayCommands() -> [String] {
        var tags: [String] = []

        let foreColor = "#cccccc "

        for skill in skillsWithMindstate() {
            let fontColor = skill.isNew ? "" : foreColor
            let tag = "\(fontColor)\(skill.description)"
            tags.append(tag)
        }

        let diff = Date().timeIntervalSince(startOfTracking!)
        tags.append("\(foreColor)\nTracking for: \(diff.formatted)")
        tags.append("\(foreColor)Last updated: \(ExpTracker.dateFormatter.string(from: Date()))")

        return ["#echo >experience @suspend@"] + tags.map {
            "#echo >experience \($0)"
        } + ["#echo >experience @resume@"]
    }
}
