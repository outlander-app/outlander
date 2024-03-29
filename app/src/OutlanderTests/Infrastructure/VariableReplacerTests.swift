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
    let variables = Variables()
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

    func test_replaces_long_variables_first_scenario2() {
        variables["pouch"] = "gem pouch"
        variables["pouch.container"] = "rucksack"

        let result = replacer.replace("get my $pouch in my $pouch.container", globalVars: variables)

        XCTAssertEqual("get my gem pouch in my rucksack", result)
    }

    func test_iteration_tests() {
        variables["testing"] = "one"
        let result = replacer.replace("$brawling_moves", globalVars: variables)
        XCTAssertEqual("$brawling_moves", result)
    }

    func test_indexed_brackets() {
        variables["weapons"] = "one|two|three"
        let result = replacer.replace("$weapons[0]", globalVars: variables)
        XCTAssertEqual("one", result)
    }

    func test_indexed_parens() {
        variables["weapons"] = "one|two|three"
        let result = replacer.replace("$weapons(0)", globalVars: variables)
        XCTAssertEqual("one", result)
    }

    func test_indexed_parens_variable_dot() {
        variables["Parse.Arcana"] = "1200|00"
        let result = replacer.replace("$Parse.Arcana(0)", globalVars: variables)
        XCTAssertEqual("1200", result)
    }

    func test_indexed_parens_missing() {
        variables["weapons"] = "one|two|three"
        let result = replacer.replace("$weapons(0", globalVars: variables)
        XCTAssertEqual("one|two|three(0", result)
    }

    func test_indexed_parens_missing_other_vars() {
        variables["weapons"] = "one|two|three"
        variables["lefthand"] = "tankard"
        let result = replacer.replace("$weapons(0  $lefthand", globalVars: variables)
        XCTAssertEqual("one|two|three(0  tankard", result)
    }

    func test_indexed_parens_missing_other_vars_other_indexed() {
        variables["weapons"] = "one|two|three"
        variables["exits"] = "north|south"
        variables["lefthand"] = "tankard"
        let result = replacer.replace("$weapons(0  $lefthand $exits[1]", globalVars: variables)
        XCTAssertEqual("one|two|three(0  tankard south", result)
    }

    func test_indexed_parens_missing_other_vars_other_indexed_middle() {
        variables["weapons"] = "one|two|three"
        variables["exits"] = "north|south"
        variables["lefthand"] = "tankard"
        let result = replacer.replace("$weapons(0  $exits[1]  $lefthand ", globalVars: variables)
        XCTAssertEqual("one|two|three(0  south  tankard ", result)
    }

    func test_indexed_chained_variables() {
        variables["list"] = "hisan|nemoih"
        variables["nemoih"] = "3"
        variables["space"] = " "
        variables["c"] = "1"
        let result = replacer.replace("$space$$list[$c]", globalVars: variables)
        XCTAssertEqual(" 3", result)
    }

    func test_indexed_chained_variables_scenario_2() {
        variables["list"] = "hisan|nemoih"
        variables["nemoih"] = "3"
        variables["space"] = " "
        variables["c"] = "1"
        let result = replacer.replace("$space$space$$list[$c]", globalVars: variables)
        XCTAssertEqual("  3", result)
    }

    func test_indexed_chained_variables_scenario_3() {
        variables["list"] = "hisan|nemoih"
        variables["nemoih"] = "3"
        variables["space"] = " "
        variables["c"] = "1"
        let result = replacer.replace("$space$$list[$c]$space", globalVars: variables)
        XCTAssertEqual(" 3 ", result)
    }

    func test_indexed_chained_variables_scenario_4() {
        variables["list"] = "hisan|nemoih"
        variables["nemoih"] = "3"
        variables["space"] = " "
        variables["c"] = "1"
        let result = replacer.replace("$$list[$c]$space$space", globalVars: variables)
        XCTAssertEqual("3  ", result)
    }

    func test_indexed_chained_variables_scenario_5() {
        variables["list"] = "hisan|nemoih"
        variables["nemoih"] = "3"
        variables["space"] = " "
        variables["c"] = "1"
        let result = replacer.replace("$$list[$c]$space$space$$list[$c]", globalVars: variables)
        XCTAssertEqual("3  3", result)
    }

    func test_delimiters() {
        let result = replacer.replace("( ) [] [one] \\( ]", globalVars: variables)
        XCTAssertEqual("( ) [] [one] \\( ]", result)
    }

    func test_mixed_delimiters() {
        variables["testing"] = "tankard"

        let result = replacer.replace("testing(0]", globalVars: variables)
        XCTAssertEqual("testing(0]", result)
    }

    func test_multiple_variables() {
        variables["skill"] = "Stealth"
        variables["Stealth.LearningRate"] = "34"

        let result = replacer.replace("$$skill.LearningRate", globalVars: variables)
        XCTAssertEqual("34", result)
    }

    func test_regex_text() {
        variables["dir"] = "swim west"

        let result = replacer.replace("matchre(\"$dir\", \"^(script|search|swim|climb|web|muck|rt|wait|slow|drag|script|room|ice) \")", globalVars: variables)
        XCTAssertEqual(result, "matchre(\"swim west\", \"^(script|search|swim|climb|web|muck|rt|wait|slow|drag|script|room|ice) \")")
    }

    func test_performance() {
        variables["weapons"] = "one|two|three"
        variables["exits"] = "north|south"
        variables["lefthand"] = "tankard"
        variables["Large_Edged.LearningRate"] = "7"
        variables["c"] = "1"
        for v in 0 ... 100_000 {
            variables["\(v)"] = UUID().uuidString
        }

        measure {
            _ = replacer.replace("$weapons(0  %another_$exits[%c]  $lefthandother $Large_Edged.LearningRate", globalVars: variables)
        }
    }
}
