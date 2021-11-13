//
//  VariableReplacerTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/12/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import XCTest

class VariableReplacerTests: XCTestCase {
    let variables = Variables(events: InMemoryEvents(), settings: ApplicationSettings())
    let replacer = VariableReplacer()

    func test_replaces_global_vars() {
        variables["charactername"] = "Obi-Wan"

        let result = replacer.replace("Greetings $charactername", globalVars: variables)

        XCTAssertEqual("Greetings Obi-Wan", result)
    }

    func test_replaces_long_variables_first() {
        variables["brawling_moves"] = "one|two|three"
        variables["brawl"] = "NO"

        let result = replacer.replace("$brawling_moves", globalVars: variables)

        XCTAssertEqual("one|two|three", result)
    }

    func test_iteration_tests() {
        variables["testing"] = "one"
        let result = replacer.replace("$brawling_moves", globalVars: variables)
        XCTAssertEqual("$brawling_moves", result)
    }
}
