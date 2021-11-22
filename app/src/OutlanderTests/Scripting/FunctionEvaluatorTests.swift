//
//  FunctionEvaluatorTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class FunctionEvaluatorTests: XCTestCase {
    let evaluator = FunctionEvaluator { val in val }

    func test_evals_math() {
        let result = evaluator.evaluateValue(.value("2+2"))
        XCTAssertEqual(result.result, "4")
    }

    func test_evals_logic() {
        let result = evaluator.evaluateBool(.value("BARD = BARD && YES = YES"))
        XCTAssertEqual(result.result, "true")
    }

    func test_evals_tolower_function() {
        let result = evaluator.evaluateValue(.function("tolower", "ABCD"))
        XCTAssertEqual(result.result, "abcd")
    }

    func test_evals_tolower_function_ignores_case() {
        let result = evaluator.evaluateValue(.function("ToLower", "ABCD"))
        XCTAssertEqual(result.result, "abcd")
    }

    func test_evals_startswith_function_success() {
        let result = evaluator.evaluateValue(.function("startswith", "one two, one"))
        XCTAssertEqual(result.result, "true")
    }

    func test_evals_startswith_function_fail() {
        let result = evaluator.evaluateValue(.function("startswith", "one two, three"))
        XCTAssertEqual(result.result, "false")
    }

    func test_evals_empty_value_to_false() {
        let expr: Expression = .value("")
        let result = evaluator.evaluateBool(expr)
        XCTAssertEqual(result.result, "false")
    }
}
