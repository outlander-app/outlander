//
//  ScriptTokenizerTests.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class ScriptTokenizerTests: XCTestCase {
    func testTokenizesComments() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("# a comment")

        switch token {
        case let .comment(text):
            XCTAssertEqual(text, "# a comment")
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesEcho() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("echo hello world")

        switch token {
        case let .echo(text):
            XCTAssertEqual(text, "hello world")
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesExit() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("exit")

        switch token {
        case .exit:
            XCTAssertTrue(true)
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesGoto() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("goto label")

        switch token {
        case let .goto(label):
            XCTAssertEqual(label, "label")
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesLabels() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("mylabel:")

        switch token {
        case let .label(label):
            XCTAssertEqual(label, "mylabel")
        default:
            XCTFail("wrong token value")
        }
    }

    func testIgnoresTextAfterLabel() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("mylabel: something something")

        switch token {
        case let .label(label):
            XCTAssertEqual(label, "mylabel")
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesMatch() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("match one two")

        switch token {
        case let .match(label, value):
            XCTAssertEqual(label, "one")
            XCTAssertEqual(value, "two")
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesMatchre() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("matchre one two")

        switch token {
        case let .matchre(label, value):
            XCTAssertEqual(label, "one")
            XCTAssertEqual(value, "two")
        default:
            XCTFail("wrong token value: \(String(describing: token))")
        }
    }

    func testTokenizesPut() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("put hello friends")

        switch token {
        case let .put(put):
            XCTAssertEqual(put, "hello friends")
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesPutWithCommands() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("put #echo a message")

        switch token {
        case let .put(put):
            XCTAssertEqual(put, "#echo a message")
        default:
            XCTFail("wrong token value")
        }
    }

    func testTokenizesWaitfor() throws {
        let tokenizer = ScriptTokenizer()
        let token = tokenizer.read("waitfor abcd")

        switch token {
        case let .waitfor(msg):
            XCTAssertEqual(msg, "abcd")
        default:
            XCTFail("wrong token value")
        }
    }
}
