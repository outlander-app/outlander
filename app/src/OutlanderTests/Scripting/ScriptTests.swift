//
//  ScriptTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class ScriptTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    @discardableResult func scenario(_ lines: [String], fileName: String = "if.cmd", expect: [String] = []) throws -> InMemoryEvents {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines[fileName] = lines
        let script = try Script(fileName, loader: loader, gameContext: context)
        script.run([], runAsync: false)

        for (index, message) in expect.enumerated() {
            XCTAssertEqual(message, events.history.dropFirst(index + 1).first?.text?.text)
        }
        return events
    }

    func testCanReadBasicScript() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)
        XCTAssertEqual(script.context.lines.count, 2)
        XCTAssertEqual(script.context.labels.count, 1)
    }

    func testCanIncludeOtherScripts() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["include util.cmd", "mylabel:", "  echo hello"]
        loader.lines["util.cmd"] = ["something:", "  echo something"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)
        XCTAssertEqual(script.context.lines.count, 4)
        XCTAssertEqual(script.context.labels.count, 2)
    }

    func testCannotIncludeItself() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["include forage.cmd", "mylabel:", "  echo hello"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)
        XCTAssertEqual(script.context.lines.count, 2)
        XCTAssertEqual(script.context.labels.count, 1)
    }

    func testReplacesExistingLabelsWhenIncludingOtherScripts() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["include util.cmd", "alabel:", "  echo hello"]
        loader.lines["util.cmd"] = ["alabel:", "  echo something"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)
        XCTAssertEqual(script.context.lines.count, 4)
        XCTAssertEqual(script.context.labels.count, 1)
    }

    func testStuff() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)
    }

    func test_argument_shift() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run(["one", "two"], runAsync: false)
        XCTAssertEqual(script.context.args, ["one", "two"])
        XCTAssertEqual(
            script.context.argumentVars.keysAndValues(),
            ["0": "one two", "1": "one", "2": "two", "3": "", "4": "", "5": "", "6": "", "7": "", "8": "", "9": ""]
        )

        script.context.shiftArgs()
        XCTAssertEqual(script.context.args, ["two"])
        XCTAssertEqual(
            script.context.argumentVars.keysAndValues(),
            ["0": "two", "1": "two", "2": "", "3": "", "4": "", "5": "", "6": "", "7": "", "8": "", "9": ""]
        )

        script.context.shiftArgs()
        XCTAssertEqual(script.context.args, [])
        XCTAssertEqual(
            script.context.argumentVars.keysAndValues(),
            ["0": "", "1": "", "2": "", "3": "", "4": "", "5": "", "6": "", "7": "", "8": "", "9": ""]
        )

        script.context.shiftArgs()
        XCTAssertEqual(script.context.args, [])
        XCTAssertEqual(
            script.context.argumentVars.keysAndValues(),
            ["0": "", "1": "", "2": "", "3": "", "4": "", "5": "", "6": "", "7": "", "8": "", "9": ""]
        )
    }

    func test_simple_echo() throws {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)

        let target = events.history.dropFirst().first?.text?.text

        XCTAssertEqual(target, "hello\n")
    }

    func test_if_else_block() throws {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines["if.cmd"] = [
            "if 1 == 2 then echo one",
            "else echo two",
        ]
        let script = try Script("if.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)

        XCTAssertEqual(events.history.dropFirst().first?.text?.text, "two\n")
    }

    func test_if_else_block_after() throws {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines["if.cmd"] = [
            "if 2 == 2 then echo one",
            "else echo two",
            "echo after",
        ]
        let script = try Script("if.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)

        XCTAssertEqual(events.history.dropFirst().first?.text?.text, "one\n")
        XCTAssertEqual(events.history.dropFirst(2).first?.text?.text, "after\n")
    }

    func test_if_else_multiline_blocks() throws {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines["if.cmd"] = [
            "if 1 == 2 then {",
            "  echo one",
            "  echo two",
            "}",
            "else {",
            "  echo three",
            "}",
            "echo after",
        ]
        let script = try Script("if.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)

        XCTAssertEqual(events.history.dropFirst().first?.text?.text, "three\n")
        XCTAssertEqual(events.history.dropFirst(2).first?.text?.text, "after\n")
    }

    func test_if_else_multiline_blocks_2() throws {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines["if.cmd"] = [
            "if 2 == 2 then {",
            "  echo one",
            "  echo two",
            "}",
            "else {",
            "  echo three",
            "}",
            "echo after",
        ]
        let script = try Script("if.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)

        XCTAssertEqual(events.history.dropFirst().first?.text?.text, "one\n")
        XCTAssertEqual(events.history.dropFirst(2).first?.text?.text, "two\n")
        XCTAssertEqual(events.history.dropFirst(3).first?.text?.text, "after\n")
    }

    func test_if_elseif_multiline_blocks_2() throws {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines["if.cmd"] = [
            "if 1 == 2 then {",
            "  echo one",
            "  echo two",
            "}",
            "else if 1 == 1 {",
            "  echo three",
            "}",
            "else {",
            "  echo four",
            "}",
            "echo after",
        ]
        let script = try Script("if.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)

        XCTAssertEqual(events.history.dropFirst().first?.text?.text, "three\n")
        XCTAssertEqual(events.history.dropFirst(2).first?.text?.text, "after\n")
    }

    func test_if_elseif_singleline_blocks_2() throws {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines["if.cmd"] = [
            "if 1 == 2 then {",
            "  echo one",
            "  echo two",
            "}",
            "else if 1 == 1 { echo three }",
            "else {",
            "  echo four",
            "}",
            "echo after",
        ]
        let script = try Script("if.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)

        XCTAssertEqual(events.history.dropFirst().first?.text?.text, "three\n")
        XCTAssertEqual(events.history.dropFirst(2).first?.text?.text, "after\n")
    }

    func test_if_blocks() throws {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines["if.cmd"] = [
            "if 1 == 2",
            "{",
            "  echo one",
            "  echo two",
            "}",
            "else",
            "{",
            "  echo four",
            "}",
            "echo after",
        ]
        let script = try Script("if.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)

        XCTAssertEqual(events.history.dropFirst().first?.text?.text, "four\n")
        XCTAssertEqual(events.history.dropFirst(2).first?.text?.text, "after\n")
    }

    func test_if_single_line_blocks() throws {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()
        loader.lines["if.cmd"] = [
            "if 1 < 2 then echo one",
            "else if 2 == 2 then echo two",
            "esel echo three",
        ]
        let script = try Script("if.cmd", loader: loader, gameContext: context)
        script.run([], runAsync: false)

        XCTAssertEqual(events.history.dropFirst().first?.text?.text, "one\n")
    }

    func test_multi_line_if_else_scenario_1() throws {
        try scenario([
            "if 1 > 2",
            "{",
            "  echo one",
            "  echo two",
            "}",
            "else if 2 == 2 {",
            "  echo three",
            "}",
            "else if 2 == 2 {",
            "  echo six",
            "}",
            "else {",
            "  echo four",
            "  echo five",
            "}",
        ],
        expect: ["three\n"])
    }

    func test_multi_line_if_else_scenario_2() throws {
        try scenario([
            "if 1 < 2",
            "{",
            "  echo one",
            "  echo two",
            "}",
            "else if 2 == 2 {",
            "  echo three",
            "}",
            "else if 2 == 2 {",
            "  echo six",
            "}",
            "else {",
            "  echo four",
            "  echo five",
            "}",
        ],
        expect: ["one\n", "two\n"])
    }

    func test_multi_line_if_else_nested() throws {
        try scenario([
            "if 1 < 2",
            "{",
            "  echo one",
            "  echo two",
            "  if 1 == 2",
            "  {",
            "    echo middle",
            "  }",
            "  else if 1 == 1 {",
            "    echo another",
            "  }",
            "  echo after",
            "}",
            "else if 2 == 2 {",
            "  echo three",
            "}",
            "else if 2 == 2 {",
            "  echo six",
            "}",
            "else {",
            "  echo four",
            "  echo five",
            "}",
            "echo end",
        ],
        expect: ["one\n", "two\n", "another\n", "after\n", "end\n"])
    }

    func test_multi_line_if_else_nested_mixed_braces() throws {
        try scenario([
            "if 1 < 2",
            "{",
            "  echo one",
            "  echo two",
            "  if 1 == 2",
            "  {",
            "    echo middle",
            "  }",
            "  else if 1 > 2 {",
            "    echo another",
            "  }",
            "  else echo or else",
            "  echo after",
            "}",
            "else if 2 == 2 {",
            "  echo three",
            "}",
            "else if 2 == 2 {",
            "  echo six",
            "}",
            "else {",
            "  echo four",
            "  echo five",
            "}",
            "echo end",
        ],
        expect: ["one\n", "two\n", "or else\n", "after\n", "end\n"])
    }
}
