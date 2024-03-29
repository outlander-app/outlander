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

    func test_semi_in_quotes() {
        let commands = "one \"two;three\"".commandsSeperated()
        XCTAssertEqual(commands, ["one \"two;three\""])
    }

    func test_semi_in_quotes_with_escaped_quote() {
        let commands = "one \"two\\\";three\"".commandsSeperated()
        XCTAssertEqual(commands, ["one \"two\\\";three\""])
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

    func test_emoji() {
        let fileName = "%F0%9F%94%A5.cmd"
        XCTAssertEqual(fileName.hexDecoededString(), "🔥.cmd")
    }

    func test_emoji_1() {
        XCTAssertEqual("\\XF0\\X9F\\X98\\X81".hexDecoededString(), "😁")
    }

    func test_emoji_2() {
        XCTAssertEqual("\\xF0\\x9F\\x98\\x81".hexDecoededString(), "😁")
    }

    func test_emoji_3() {
        XCTAssertEqual("%F0%9F%98%81".hexDecoededString(), "😁")
    }
}
