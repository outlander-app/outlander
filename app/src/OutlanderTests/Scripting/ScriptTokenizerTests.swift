//
//  ScriptTokenizerTests.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class ScriptTokenizerTests: XCTestCase {
    func testTokenizesLabels() throws {
        let tokenizer = ScriptTokenizer()
        let result = tokenizer.read("mylabel:")

        XCTAssertEqual(result.count, 1)

        let token = result.first
        switch token {
        case let .label(label):
            XCTAssertEqual(label, "mylabel")
        default:
            XCTFail("wrong token value")
        }
    }

    func testIgnoresTextAfterLabel() throws {
        let tokenizer = ScriptTokenizer()
        let result = tokenizer.read("mylabel: something something")

        XCTAssertEqual(result.count, 1)

        let token = result.first
        switch token {
        case let .label(label):
            XCTAssertEqual(label, "mylabel")
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesEcho() throws {
        let tokenizer = ScriptTokenizer()
        let result = tokenizer.read("echo hello world")

        XCTAssertEqual(result.count, 1)

        let token = result.first
        switch token {
        case let .echo(text):
            XCTAssertEqual(text, "hello world")
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesComments() throws {
        let tokenizer = ScriptTokenizer()
        let result = tokenizer.read("# a comment")

        XCTAssertEqual(result.count, 1)

        let token = result.first
        switch token {
        case let .comment(text):
            XCTAssertEqual(text, "# a comment")
        default:
            XCTFail("wrong token value")
        }
    }
}
