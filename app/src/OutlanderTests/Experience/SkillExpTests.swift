//
//  SkillExpTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/4/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class SkillExpTests: XCTestCase {
    func test_fa() {
        let skill = SkillExp()
        skill.name = "First_Aid"
        skill.ranks = 503.55
        skill.originalRanks = 499.20
        skill.mindState = .considering

        XCTAssertEqual(skill.description, "       First Aid:  503 55%   (6/34) +4.35")
    }

    func test_double() {
        let skill = SkillExp()
        skill.name = "First_Aid"
        skill.ranks = 53.55
        skill.originalRanks = 49.20
        skill.mindState = .considering

        XCTAssertEqual(skill.description, "       First Aid:   53 55%   (6/34) +4.35")
    }

    func test_1k() {
        let skill = SkillExp()
        skill.name = "Outdoorsmanship"
        skill.ranks = 1503.55
        skill.originalRanks = 1499.20
        skill.mindState = .mindLock

        XCTAssertEqual(skill.description, " Outdoorsmanship: 1503 55%  (34/34) +4.35")
    }

    func test_negative() {
        let skill = SkillExp()
        skill.name = "Outdoorsmanship"
        skill.ranks = 1503.50
        skill.originalRanks = 1504.00
        skill.mindState = .mindLock

        XCTAssertEqual(skill.description, " Outdoorsmanship: 1503 50%  (34/34) -0.50")
    }
}
