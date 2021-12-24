//
//  FunctionEvaluatorTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class FunctionEvaluatorTests: XCTestCase {
    let evaluator = FunctionEvaluator(GameContext(InMemoryEvents())) { val in val }

    func test_evals_math() {
        let result = evaluator.evaluateValue(.value("2+2"))
        XCTAssertEqual(result.result, "4")
    }

    func test_evals_logic() {
        let result = evaluator.evaluateBool(.value("BARD == BARD && YES == YES"))
        XCTAssertEqual(result.result, "true")
    }

    func test_evals_logic_single_equals() {
        let result = evaluator.evaluateBool(.value("BARD = BARD && YES = YES"))
        XCTAssertEqual(result.result, "true")
    }

    // TODO: not sure if I want to try to support this - messes with regexes - can fix it now with parsing
//    func test_evals_logic_single_or() {
//        let result = evaluator.evaluateBool(.value("BARD = BARD | YES = NO"))
//        XCTAssertEqual(result.result, "true")
//    }
//
//    func test_evals_logic_single_and() {
//        let result = evaluator.evaluateBool(.value("BARD = BARD & YES = YES"))
//        XCTAssertEqual(result.result, "true")
//    }

    func test_evals_tolower_function() {
        let result = evaluator.evaluateStrValue(.function("tolower", ["ABCD"]))
        XCTAssertEqual(result.result, "abcd")
    }

    func test_evals_tolower_function_ignores_case() {
        let result = evaluator.evaluateStrValue(.function("ToLower", ["ABCD"]))
        XCTAssertEqual(result.result, "abcd")
    }

    func test_evals_startswith_function_success() {
        let result = evaluator.evaluateStrValue(.function("startswith", ["\"one two\"", "one"]))
        XCTAssertEqual(result.result, "true")
    }

    func test_evals_startswith_function_fail() {
        let result = evaluator.evaluateStrValue(.function("startswith", ["\"one two\"", "three"]))
        XCTAssertEqual(result.result, "false")
    }

    func test_evals_empty_value_to_false() {
        let expr: ScriptExpression = .value("")
        let result = evaluator.evaluateBool(expr)
        XCTAssertEqual(result.result, "false")
    }

    func test_evals_func() {
        let result = evaluator.evaluateStrValue(.values([.function("tolower", ["ONE"]), .value("== one")]))
        XCTAssertTrue(result.result.toBool() == true)
    }

    func test_evals_func_2() {
        let result = evaluator.evaluateBool(.values([.value("(3 == 4) || 2 ==  1 ||"), .function("tolower", ["ONE"]), .value("== one")]))
        XCTAssertTrue(result.result.toBool() == true)
    }

    func test_evals_func_name_ignores_case() {
        let result = evaluator.evaluateBool(.values([.function("ToLower", ["ONE"]), .value("== one")]))
        XCTAssertTrue(result.result.toBool() == true)
    }

    func test_contains_ignores_casing() {
        let result = evaluator.evaluateBool(.values([.function("contains", ["have ONE", "one"])]))
        XCTAssertTrue(result.result.toBool() == true)
    }

    func test_evals_func_with_leading_not() {
        let result = evaluator.evaluateBool(.values([.value("!"), .function("contains", ["have one", "one"])]))
        XCTAssertTrue(result.result.toBool() == false)
    }

    func test_evals_func_with_leading_double_not() {
        let result = evaluator.evaluateBool(.values([.value("!!"), .function("contains", ["have one", "one"])]))
        XCTAssertTrue(result.result.toBool() == true)
    }

    func test_evals_math_round() {
        let result = evaluator.evaluateValue(.value("round(5.5)"))
        XCTAssertEqual(result.result, "6")
    }

    func test_evals_math_ceil() {
        let result = evaluator.evaluateValue(.value("ceil(5.5)"))
        XCTAssertEqual(result.result, "6")
    }

    func test_evals_math_floor() {
        let result = evaluator.evaluateValue(.value("floor(5.5)"))
        XCTAssertEqual(result.result, "5")
    }
}
