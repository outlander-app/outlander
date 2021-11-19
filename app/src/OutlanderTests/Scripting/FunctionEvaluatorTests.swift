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
}
