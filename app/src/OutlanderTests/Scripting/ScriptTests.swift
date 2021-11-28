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

    @discardableResult func scenario(_ lines: [String], fileName: String = "if.cmd", globalVars: [String: String] = [:], variables: [String: String] = [:], expect: [String] = [], args: [String] = []) throws -> InMemoryEvents {
        let events = InMemoryEvents()
        let context = GameContext(events)
        let loader = InMemoryScriptLoader()

        for v in globalVars {
            context.globalVars[v.key] = v.value
        }

        loader.lines[fileName] = lines
        let script = try Script(fileName, loader: loader, gameContext: context)
        
        for v in variables {
            script.context.variables[v.key] = v.value
        }

        script.run(args, runAsync: false)

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
            "else echo three",
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
            "else if 2 == 2",
            "{",
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

    func test_multi_line_if_else_tripple_nested_mixed_braces() throws {
        try scenario([
            "if 1 < 2",
            "{",
            "  echo one",
            "  echo two",
            "  if 1 == 2",
            "  {",
            "    echo middle",
            "  }",
            "  else if 2 > 1 {",
            "    echo another",
            "    if 2 == 2 then",
            "    {",
            "      echo trippple threat",
            "      if 3 < 1 then {",
            "        echo do some things",
            "        echo and more things",
            "      }",
            "      else { echo not those things }",
            "    }",
            "    echo after threat",
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
            "if 3 == 3 then { echo yarg }",
        ],
        expect: ["one\n", "two\n", "another\n", "trippple threat\n", "not those things\n", "after threat\n", "after\n", "end\n", "yarg\n"])
    }

    func test_skipping_big_blocks() throws {
        try scenario([
            "if 1 > 2",
            "{",
            "  echo one",
            "  echo two",
            "  if 1 == 2",
            "  {",
            "    echo middle",
            "  }",
            "  else if 2 > 1 {",
            "    echo another",
            "    if 2 == 2 then",
            "    {",
            "      echo trippple threat",
            "      if 3 < 1 then {",
            "        echo do some things",
            "        echo and more things",
            "      }",
            "      else { echo not those things }",
            "    }",
            "    echo after threat",
            "  }",
            "  else echo or else",
            "  echo after",
            "}",
            "else if 3 == 2 {",
            "  echo three",
            "}",
            "else if 3 == 2 {",
            "  echo six",
            "}",
            "echo end",
            "if 3 == 3 then { echo yarg }",
        ],
        expect: ["end\n", "yarg\n"])
    }

    func test_single_line_no_then_with_braces() throws {
        try scenario([
            "if 3 == 3 { echo yarg }",
        ],
        expect: ["yarg\n"])
    }

    func test_else() throws {
        try scenario([
            "if_2 { echo yep one! }",
            "else {",
            "  echo else!",
            "}",
        ],
        expect: ["else!\n"],
        args: ["one"])
    }

    func test_else_scenario_2() throws {
        try scenario([
            "if_1 { echo yep one! }",
            "else {",
            "  echo else!",
            "}",
        ],
        expect: ["yep one!\n"],
        args: ["one"])
    }

    func test_else_scenario_3() throws {
        try scenario([
            "if_0 { echo yep one! }",
            "else {",
            "  echo else!",
            "}",
        ],
        expect: ["yep one!\n"])
    }

    func test_matchre() throws {
        try scenario([
            "var exp_threshold 10",
            "if matchre(\"%2\", \"^\\d+$\") then {",
            "  var exp_threshold %2",
            "}",
            "echo %exp_threshold",
        ],
        expect: ["25\n"],
        args: ["exp", "25"])
    }

    func test_matchre_with_and_expression() throws {
        try scenario([
            "var exp_threshold 10",
            "if matchre(\"%2\", \"^\\d+$\") && 2==2 then {",
            "  var exp_threshold %2",
            "}",
            "echo %exp_threshold",
        ],
        expect: ["25\n"],
        args: ["exp", "25"])
    }

    func test_matchre_with_or_expression() throws {
        try scenario([
            "var exp_threshold 10",
            "if matchre(\"%2\", \"^\\d+$\") || 2==2 then {",
            "  var exp_threshold %2",
            "}",
            "echo %exp_threshold",
        ],
        expect: ["abcd\n"],
        args: ["exp", "abcd"])
    }

    func test_matchre_with_or_expression_different_order() throws {
        try scenario([
            "var exp_threshold 10",
            "if 2==2 || matchre(\"%2\", \"^\\d+$\") then {",
            "  var exp_threshold %2",
            "}",
            "echo %exp_threshold",
        ],
        expect: ["abcd\n"],
        args: ["exp", "abcd"])
    }

    func test_matchre_with_tripple_or_expression() throws {
        try scenario([
            "var exp_threshold 10",
            "if matchre(\"%2\", \"^\\d+$\") || 1 == 2 || 2==2 then {",
            "  var exp_threshold %2",
            "}",
            "echo %exp_threshold",
        ],
        expect: ["abcd\n"],
        args: ["exp", "abcd"])
    }

    func test_eval_replacere() throws {
        try scenario([
            "var dir swim southwest",
            "eval dir replacere(\"%dir\", \"^(script |search|swim|web|muck|rt|wait|slow|script|room|ice) \", \"\")",
            "echo %dir",
        ],
        expect: ["southwest\n"])
    }

    func test_if_true_string() throws {
        try scenario([
            "var temp True",
            "if (%temp) then { echo var is true }",
            "else echo nope!",
        ],
        expect: ["var is true\n"])
    }

    func test_variables() throws {
        try scenario([
            "var next_weapon Offhand_Weapon",
            "var temp_weapon Large_Edged",
            "if $%next_weapon.LearningRate < $%temp_weapon.LearningRate then { echo var is true }",
            "else echo nope!",
        ],
        globalVars: [
            "Offhand_Weapon.LearningRate": "5",
            "Large_Edged.LearningRate": "7"
        ],
        expect: ["var is true\n"])
    }

    func test_math_add_time() throws {
        try scenario([
            "var hunt_timer 32",
            "var temp $gametime",
            "math temp add %hunt_timer",
            "echo %temp"
        ],
        globalVars: [
            "gametime": "1638082872",
        ],
        expect: ["1638082904\n"])
    }
}
