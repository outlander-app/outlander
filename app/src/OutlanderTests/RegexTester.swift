//
//  RegexTester.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/16/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class RegexTester: XCTestCase {
    override func setUp() {}

    override func tearDown() {}

    func test_replace() {
        let text = "flickering mana to the west\n"
        let regex = try! Regex("flickering mana to the", options: [])

        let result = regex.replace(text, with: "flickering mana (8/21) to the")

        XCTAssertEqual(result, "flickering mana (8/21) to the west\n")
    }

    func test_replace2() {
        let text = "flickering mana to the west\n"

        let result = text.replacingOccurrences(of: "flickering mana to the", with: "flickering mana (8/21) to the")

        XCTAssertEqual(result, "flickering mana (8/21) to the west\n")
    }

    func test_matches() {
        let regText = "titanese cloth|imperial weave cloth|dergatine cloth|arzumodine cloth|zenganne cloth"
        let regex = try! Regex(regText, options: .caseInsensitive)

        var text = "some other text Imperial weave cloth and some more"
        let match = regex.firstMatch(&text)!

        XCTAssertEqual(match.count, 1)
        XCTAssertEqual(match.values(), ["Imperial weave cloth"])
    }

//    func test_mesure() {
//        var text = "        Thievery:    887 46.22% engaged       (22/34)"
//
//        measure {
//            let regex = try! Regex("Thievery:\\s+(\\d+) (\\d{2})\\.(\\d{2})%", options: [.caseInsensitive])
//            _ = regex.firstMatch(&text)
//        }
//    }
//
//    func test_mesure_2() {
//        var text = "Thievery:    887 46.22% engaged       (22/34)"
//
//        measure {
//            let regex = try! Regex("Thievery:\\s+(\\d+) (\\d{2})\\.(\\d{2})%", options: [.caseInsensitive])
//            _ = regex.firstMatch(&text)
//        }
//    }
}
