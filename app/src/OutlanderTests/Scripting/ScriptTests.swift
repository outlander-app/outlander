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

    @discardableResult func scenario(_ lines: [String], fileName: String = "if", globalVars: [String: String] = [:], variables: [String: String] = [:], expect: [String] = [], args: [String] = []) throws -> InMemoryEvents {
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
            XCTAssertEqual(message, events.history.dropFirst(index + 2).first?.text?.text)
        }
        return events
    }

    func testCanReadBasicScript() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage", loader: loader, gameContext: context)
        script.run([], runAsync: false)
        XCTAssertEqual(script.context.lines.count, 2)
        XCTAssertEqual(script.context.labels.count, 1)
    }

    func testCanIncludeOtherScripts() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage"] = ["include util", "mylabel:", "  echo hello"]
        loader.lines["util"] = ["something:", "  echo something"]
        let script = try Script("forage", loader: loader, gameContext: context)
        script.run([], runAsync: false)
        XCTAssertEqual(script.context.lines.count, 4)
        XCTAssertEqual(script.context.labels.count, 2)
    }

    func testCannotIncludeItself() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage"] = ["include forage", "mylabel:", "  echo hello"]
        let script = try Script("forage", loader: loader, gameContext: context)
        script.run([], runAsync: false)
        XCTAssertEqual(script.context.lines.count, 2)
        XCTAssertEqual(script.context.labels.count, 1)
    }

    func testReplacesExistingLabelsWhenIncludingOtherScripts() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage"] = ["include util", "alabel:", "  echo hello"]
        loader.lines["util"] = ["alabel:", "  echo something"]
        let script = try Script("forage", loader: loader, gameContext: context)
        script.run([], runAsync: false)
        XCTAssertEqual(script.context.lines.count, 4)
        XCTAssertEqual(script.context.labels.count, 1)
    }

    func testStuff() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage", loader: loader, gameContext: context)
        script.run([], runAsync: false)
    }

    func test_argument_shift() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage", loader: loader, gameContext: context)
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
        try scenario([
            "mylabel:",
            "  echo hello",
        ],
        expect: ["hello\n"])
    }

    func test_if_else_block() throws {
        try scenario([
            "if 1 == 2 then echo one",
            "else echo two",
        ],
        expect: ["two\n"])
    }

    func test_if_else_block_after() throws {
        try scenario([
            "if 2 == 2 then echo one",
            "else echo two",
            "echo after",
        ],
        expect: ["one\n", "after\n"])
    }

    func test_if_else_multiline_blocks() throws {
        try scenario([
            "if 1 == 2 then {",
            "  echo one",
            "  echo two",
            "}",
            "else {",
            "  echo three",
            "}",
            "echo after",
        ],
        expect: ["three\n", "after\n"])
    }

    func test_if_else_multiline_blocks_2() throws {
        try scenario([
            "if 2 == 2 then {",
            "  echo one",
            "  echo two",
            "}",
            "else {",
            "  echo three",
            "}",
            "echo after",
        ],
        expect: ["one\n", "two\n", "after\n"])
    }

    func test_if_elseif_multiline_blocks_2() throws {
        try scenario([
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
        ],
        expect: ["three\n", "after\n"])
    }

    func test_if_elseif_singleline_blocks_2() throws {
        try scenario([
            "if 1 == 2 then {",
            "  echo one",
            "  echo two",
            "}",
            "else if 1 == 1 { echo three }",
            "else {",
            "  echo four",
            "}",
            "echo after",
        ],
        expect: ["three\n", "after\n"])
    }

    func test_if_blocks() throws {
        try scenario([
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
        ],
        expect: ["four\n", "after\n"])
    }

    func test_if_single_line_blocks() throws {
        try scenario([
            "if 1 < 2 then echo one",
            "else if 2 == 2 then echo two",
            "else echo three",
        ],
        expect: ["one\n"])
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
            "Large_Edged.LearningRate": "7",
        ],
        expect: ["var is true\n"])
    }

    func test_math_add_time() throws {
        try scenario([
            "var hunt_timer 32",
            "var temp $gametime",
            "math temp add %hunt_timer",
            "echo %temp",
        ],
        globalVars: [
            "gametime": "1638082872",
        ],
        expect: ["1638082904\n"])
    }

    func test_skips_multi_singleline_if_blocks() throws {
        try scenario([
            "if false then {",
            "  if true then echo one",
            "  else if true then echo two",
            "  else echo three",
            "  echo after",
            "}",
            "echo end",
        ],
        expect: ["end\n"])
    }

    func test_skips_multi_singleline_if_blocks_elseif_with_body() throws {
        try scenario([
            "if false then {",
            "  if true then echo one",
            "  else if {",
            "    echo else if",
            "  }",
            "  else echo else",
            "  echo after",
            "}",
            "echo end",
        ],
        expect: ["end\n"])
    }

    func test_skips_multi_singleline_if_blocks_else_with_body() throws {
        try scenario([
            "if false then {",
            "  if true then echo one",
            "  else if true then echo two",
            "  else {",
            "    echo else",
            "  }",
            "  echo after",
            "}",
            "echo end",
        ],
        expect: ["end\n"])
    }

    func test_not_equal_strings() throws {
        try scenario([
            "if (\"$lefthand\" != \"Empty\") then { echo not equal }",
            "echo end",
        ],
        expect: ["not equal\n", "end\n"])
    }

    func test_if_arg_single_line() throws {
        try scenario([
            "if_1 then {echo yep}",
            "echo end",
        ],
        expect: ["yep\n", "end\n"],
        args: ["one"])
    }

    func test_if_arg_with_then() throws {
        try scenario([
            "if_1 then {",
            "  echo yep",
            "}",
            "echo end",
        ],
        expect: ["yep\n", "end\n"],
        args: ["one"])
    }

    func test_if_arg_needs_brace() throws {
        try scenario([
            "if_1",
            "{",
            "  echo yep",
            "}",
            "echo end",
        ],
        expect: ["yep\n", "end\n"],
        args: ["one"])
    }

    func test_if_arg_needs_brace_with_then() throws {
        try scenario([
            "if_1 then",
            "{",
            "  echo yep",
            "}",
            "echo end",
        ],
        expect: ["yep\n", "end\n"],
        args: ["one"])
    }

    func test_if_arg_needs_brace_with_then_elseif_single_line() throws {
        try scenario([
            "if_2 then",
            "{",
            "  echo two",
            "}",
            "else if_1 then echo one",
            "echo end",
        ],
        expect: ["one\n", "end\n"],
        args: ["one"])
    }

    func test_if_arg_needs_brace_with_then_else_single_line() throws {
        try scenario([
            "if_2 then",
            "{",
            "  echo two",
            "}",
            "else echo one",
            "echo end",
        ],
        expect: ["one\n", "end\n"],
        args: ["one"])
    }

    func test_if_arg_needs_brace_with_then_with_if_after() throws {
        try scenario([
            "if_1 then",
            "{",
            "  echo one",
            "}",
            "if 1 == 1 then echo yes",
            "echo end",
        ],
        expect: ["one\n", "yes\n", "end\n"],
        args: ["one"])
    }

    func test_if_arg_inner_ifs() throws {
        try scenario([
            "if_1 then {",
            "  if 1 == 1 then echo one",
            "  if 1 == 1 then echo two",
            "}",
            "if 1 == 1 then echo after",
            "echo end",
        ],
        expect: ["one\n", "two\n", "after\n", "end\n"],
        args: ["one"])
    }

    func test_if_arg_inner_ifs_no_args() throws {
        try scenario([
            "if_1 then {",
            "  if 1 == 1 then echo one",
            "  if 1 == 1 then echo two",
            "}",
            "if 1 == 1 then echo after",
            "echo end",
        ],
        expect: ["after\n", "end\n"],
        args: [])
    }

    func test_replacere() throws {
        try scenario([
            "var replacedList a juvenile wyvern,,a juvenile wyvern,a juvenile wyvern,a juvenile wyvern",
            "eval replacedList replacere(\"%replacedList\", \",{2,}\", \",\")",
            "echo %replacedList",
        ],
        expect: ["a juvenile wyvern,a juvenile wyvern,a juvenile wyvern,a juvenile wyvern\n"])
    }

    func test_matchre_replacement() throws {
        try scenario([
            "if ($monstercount > 0) then {",
            "    if matchre(\"$monsterlist\",\"(\\w+)$\") then {",
            "        echo monsterlist = $monsterlist",
            "        echo $1",
            "    }",
            "}",
        ],
        globalVars: ["monsterlist": "a kobold|a kobold|a golden jackal", "monstercount": "3"],
        expect: ["monsterlist = a kobold|a kobold|a golden jackal\n", "jackal\n"])
    }

    func test_matchre_replacement_scenario2() throws {
        try scenario([
            "var test You glance down to see an unfinished red-leucro headband in your right hand and some razor sharp scissors crafted from animite in your left hand.",
            "if (matchre(\"%test\", \"^You glance down to see (.+) in your right hand and (.+) in your left hand\\.$\")) {",
            "  echo $1",
            "  echo $2",
            "}",
        ],
        expect: ["an unfinished red-leucro headband\n", "some razor sharp scissors crafted from animite\n"])
    }

    func test_eval_numbers() throws {
        try scenario([
            "eval temp 1+1",
            "echo %temp",
        ],
        expect: ["2\n"])
    }

    func test_eval_numbers_senario_2() throws {
        try scenario([
            "eval temp 1.6+1.5",
            "echo %temp",
        ],
        expect: ["3.1\n"])
    }

    func test_math_works_without_variable_previously_defined() throws {
        try scenario([
            "math temp - 1",
            "echo %temp",
        ],
        expect: ["-1\n"])
    }

    func test_math_work_with_variable_defined_as_blank() throws {
        try scenario([
            "var temp",
            "math temp - 1",
            "echo %temp",
        ],
        expect: ["-1\n"])
    }

    func test_math_subtract_numbers_senario_1() throws {
        try scenario([
            "var temp 2",
            "math temp - 1",
            "echo %temp",
        ],
        expect: ["1\n"])
    }

    func test_math_add_numbers_senario_1() throws {
        try scenario([
            "var temp 2",
            "math temp + 1",
            "echo %temp",
        ],
        expect: ["3\n"])
    }

    func test_math_divide_numbers_senario_1() throws {
        try scenario([
            "var temp 4",
            "math temp / 2",
            "echo %temp",
        ],
        expect: ["2\n"])
    }

    func test_math_modulus_numbers_senario_1() throws {
        try scenario([
            "var temp 4",
            "math temp % 3",
            "echo %temp",
        ],
        expect: ["1\n"])
    }

    func test_math_divide_by_zero() throws {
        try scenario([
            "var temp 4",
            "math temp / 0",
            "echo %temp",
        ],
        expect: ["[if(2)]: cannot divide by zero!\n"])
    }

    func test_can_variable_replace_shorter_words_combined() throws {
        try scenario([
            "var tarantulaSkillSet Weapon",
            "echo %tarantulaSkillSets",
        ],
        expect: ["Weapons\n"])
    }
}
