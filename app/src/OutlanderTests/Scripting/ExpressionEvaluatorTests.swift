//
//  ExpressionEvaluatorTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class ExpressionEvaluatorTests: XCTestCase {
    let evaluator = ExpressionEvaluator()

    func test_evals_nothing() {
        let result = evaluator.evaluateLogic("")
        XCTAssertFalse(result)
    }

    func test_evals_single_value() {
        let result = evaluator.evaluateLogic("3")
        XCTAssertFalse(result)
    }

    func test_evals_numbers() {
        let result = evaluator.evaluateLogic("1 > 2")
        XCTAssertFalse(result)
    }

    func test_evals_numbers_2() {
        let result = evaluator.evaluateLogic("1 < 2")
        XCTAssertTrue(result)
    }

    func test_evals_strings() {
        var result = evaluator.evaluateLogic("one > two")
        XCTAssertFalse(result)

        result = evaluator.evaluateLogic("two > one")
        XCTAssertFalse(result)
    }

    func test_string_equality() {
        var result = evaluator.evaluateLogic("\"one\" == \"two\"")
        XCTAssertFalse(result)

        result = evaluator.evaluateLogic("\"one\" = \"two\"")
        XCTAssertFalse(result)

        result = evaluator.evaluateLogic("one == two")
        XCTAssertTrue(result)

        result = evaluator.evaluateLogic("one = two")
        XCTAssertTrue(result)

        result = evaluator.evaluateLogic("two == two")
        XCTAssertTrue(result)

        result = evaluator.evaluateLogic("two = two")
        XCTAssertTrue(result)

        result = evaluator.evaluateLogic("\"two\" = \"two\"")
        XCTAssertTrue(result)

        result = evaluator.evaluateLogic("\"two\" == \"two\"")
        XCTAssertTrue(result)

        result = evaluator.evaluateLogic("two == \"two\"")
        XCTAssertFalse(result)
    }

    func test_evals_expressions() {
        var result = evaluator.evaluateLogic("2+2=4")
        XCTAssertTrue(result)

        result = evaluator.evaluateLogic("2+2<4")
        XCTAssertFalse(result)

        result = evaluator.evaluateLogic("2+2<4 || 3*2=6")
        XCTAssertTrue(result)
    }

    func test_can_add_numbers() {
        let result: Int? = evaluator.evaluateValue("5 + 2")
        XCTAssertEqual(result, 7)
    }

    func test_value_empty() {
        let result: Int? = evaluator.evaluateValue("")
        XCTAssertNil(result)
    }

    func test_single_value() {
        let result: Int? = evaluator.evaluateValue("5")
        XCTAssertEqual(result, 5)
    }

    func test_single_string() {
        let result: Int? = evaluator.evaluateValue("abcd")
        XCTAssertNil(result)
    }

    func test_bogus_value() {
        let result: Int? = evaluator.evaluateValue("one + %onetwo")
        XCTAssertNil(result)
    }

    func test_double() {
        let result: Double? = evaluator.evaluateValue("3 + 3.5")
        XCTAssertEqual(result, 6.5)
    }

    func test_double_ints() {
        let result: Double? = evaluator.evaluateValue("3 + 3")
        XCTAssertEqual(result, 6.0)
    }
}
