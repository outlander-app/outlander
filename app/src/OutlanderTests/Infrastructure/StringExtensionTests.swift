//
//  StringExtensionTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/9/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import XCTest

class SplitToCommandsTests: XCTestCase {
    func test_simple_split() {
        let commands = "one;two".commandsSeperated()
        XCTAssertEqual(commands, ["one", "two"])
    }

    func test_single() {
        let commands = "one".commandsSeperated()
        XCTAssertEqual(commands, ["one"])
    }

    func test_escaped() {
        let commands = "one\\;two;three".commandsSeperated()
        XCTAssertEqual(commands, ["one;two", "three"])
    }

    func test_escaped_measure() {
        measure {
            _ = "one\\;two;three".commandsSeperated()
            _ = "#var Obfuscation 0;#echo >log #990000 Obfuscation wore off".commandsSeperated()
            _ = "room recite neath the depths of darkness i go\\;to 'scape the prying eyes of light\\;under dragon's spine i crawl\\;to crawl out from under the dragon's shadow".commandsSeperated()
        }
    }

    func test_split_quotes() {
        let commands = "one \"two three\"".argumentsSeperated()
        XCTAssertEqual(commands, ["one", "\"two three\""])
    }

    func test_split_no_quotes() {
        let commands = "one".argumentsSeperated()
        XCTAssertEqual(commands, ["one"])
    }

    func test_split_multiple_quotes() {
        let commands = "\"one\" two \"three\"".argumentsSeperated()
        XCTAssertEqual(commands, ["\"one\"", "two", "\"three\""])
    }

    func test_split_missing_quotes() {
        let commands = "one \"two three".argumentsSeperated()
        XCTAssertEqual(commands, ["one", "\"two three"])
    }
}
