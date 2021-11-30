//
//  LearningRate.swift
//  Outlander
//
//  Created by Joe McBride on 11/4/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

enum LearningRate: Int {
    case clear = 0
    case dabbling = 1
    case perusing = 2
    case learning = 3
    case thoughtful = 4
    case thinking = 5
    case considering = 6
    case pondering = 7
    case ruminating = 8
    case concentrating = 9
    case attentive = 10
    case deliberative = 11
    case interested = 12
    case examining = 13
    case understanding = 14
    case absorbing = 15
    case intrigued = 16
    case scrutinizing = 17
    case analyzing = 18
    case studious = 19
    case focused = 20
    case veryFocused = 21
    case engaged = 22
    case veryEngaged = 23
    case cogitating = 24
    case fascinated = 25
    case captivated = 26
    case engrossed = 27
    case riveted = 28
    case veryRiveted = 29
    case rapt = 30
    case veryRapt = 31
    case enthralled = 32
    case nearlyLocked = 33
    case mindLock = 34
}

extension LearningRate: Comparable {
    static func < (lhs: LearningRate, rhs: LearningRate) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

let learningRateLookup: [String: LearningRate] = [
    "clear": .clear,
    "dabbling": .dabbling,
    "perusing": .perusing,
    "learning": .learning,
    "thoughtful": .thoughtful,
    "thinking": .thinking,
    "considering": .considering,
    "pondering": .pondering,
    "ruminating": .ruminating,
    "concentrating": .concentrating,
    "attentive": .attentive,
    "deliberative": .deliberative,
    "interested": .interested,
    "examining": .examining,
    "understanding": .understanding,
    "absorbing": .absorbing,
    "intrigued": .intrigued,
    "scrutinizing": .scrutinizing,
    "analyzing": .analyzing,
    "studious": .studious,
    "focused": .focused,
    "very focused": .veryFocused,
    "engaged": .engaged,
    "very engaged": .veryEngaged,
    "cogitating": .cogitating,
    "fascinated": .fascinated,
    "captivated": .captivated,
    "engrossed": .engrossed,
    "riveted": .riveted,
    "very riveted": .veryRiveted,
    "rapt": .rapt,
    "very rapt": .veryRapt,
    "enthralled": .enthralled,
    "nearly locked": .nearlyLocked,
    "mind lock": .mindLock,
]

extension LearningRate: CustomStringConvertible {
    var description: String {
        switch self {
        case .clear:
            return "clear"
        case .dabbling:
            return "dabbling"
        case .perusing:
            return "persuing"
        case .learning:
            return "learning"
        case .thoughtful:
            return "thoughtful"
        case .thinking:
            return "thinking"
        case .considering:
            return "considering"
        case .pondering:
            return "pondering"
        case .ruminating:
            return "ruminating"
        case .concentrating:
            return "concentrating"
        case .attentive:
            return "attentive"
        case .deliberative:
            return "deliberative"
        case .interested:
            return "interested"
        case .examining:
            return "examining"
        case .understanding:
            return "understanding"
        case .absorbing:
            return "absorbing"
        case .intrigued:
            return "intrigued"
        case .scrutinizing:
            return "scrutinizing"
        case .analyzing:
            return "analyzing"
        case .studious:
            return "studious"
        case .focused:
            return "focused"
        case .veryFocused:
            return "very focused"
        case .engaged:
            return "engaged"
        case .veryEngaged:
            return "very engaged"
        case .cogitating:
            return "cogitating"
        case .fascinated:
            return "fascinated"
        case .captivated:
            return "captivated"
        case .engrossed:
            return "engrossed"
        case .riveted:
            return "riveted"
        case .veryRiveted:
            return "very riveted"
        case .rapt:
            return "rapt"
        case .veryRapt:
            return "very rapt"
        case .enthralled:
            return "enthralled"
        case .nearlyLocked:
            return "nearly locked"
        case .mindLock:
            return "mind lock"
        }
    }
}
