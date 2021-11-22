//
//  ExpressionTokenizerTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/21/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class ExpressionTokenizerTests: XCTestCase {
    let tokenizer = ExpressionTokenizer()

    func test_reads_expression() {
        let result = tokenizer.read("1==1")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "1==1")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "")
    }

    func test_reads_expression_with_left_over() {
        let result = tokenizer.read("1==1 { echo hello }")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "1==1")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{ echo hello }")
    }

    func test_reads_expression_with_then_left_over() {
        let result = tokenizer.read("3 == 3 then { echo yarg another }")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "3 ==3")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{ echo yarg another }")
    }

    func test_reads_expression_with_then_left_over_scenario2() {
        let result = tokenizer.read("1==1 then { echo hello }")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "1==1")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{ echo hello }")
    }

    func test_reads_expression_with_then_left_over_brace_only() {
        let result = tokenizer.read("1==1 then {")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "1==1")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{")
    }

    func test_reads_expression_with_then_nothing_left_over() {
        let result = tokenizer.read("1==1 then ")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "1==1")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "")
    }

    func test_reads_expression_with_then_no_braces() {
        let result = tokenizer.read("1==1 then echo hello")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "1==1")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "echo hello")
    }

    func test_reads_expression_with_parens() {
        let result = tokenizer.read("(1==1) then echo hello")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "(1==1)")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "echo hello")
    }

    func test_reads_expression_with_parens_no_spaces() {
        let result = tokenizer.read("(1==1){")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "(1==1)")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{")
    }

    func test_reads_expression_with_quotes() {
        let result = tokenizer.read("(\"%one\" == \"%two\"){")

        switch result.expression {
        case let .value(txt):
            XCTAssertEqual(txt, "(\"%one\"==\"%two\")")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{")
    }

    func test_reads_function() {
        let result = tokenizer.read("tolower(ABCD){")

        switch result.expression {
        case let .function(name, args):
            XCTAssertEqual(name, "tolower")
            XCTAssertEqual(args, "ABCD")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{")
    }

    func test_reads_function_multi_params() {
        let result = tokenizer.read("tolower(one, two, three){")

        switch result.expression {
        case let .function(name, args):
            XCTAssertEqual(name, "tolower")
            XCTAssertEqual(args, "one, two, three")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{")
    }

    func test_reads_function_multi_params_quoted() {
        let result = tokenizer.read("tolower(\"one\", two, \"three\"){")

        switch result.expression {
        case let .function(name, args):
            XCTAssertEqual(name, "tolower")
            XCTAssertEqual(args, "\"one\", two, \"three\"")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{")
    }

    func test_reads_two_logical_functions() {
        let result = tokenizer.read("tolower(ONE) || tocaps(TWO) {")

        switch result.expression {
        case let .expression(left, op, right):
            XCTAssertEqual(left.description, "tolower(ONE)")
            XCTAssertEqual(op, "||")
            XCTAssertEqual(right.description, "tocaps(TWO)")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{")
    }

    func test_reads_three_logical_functions() {
        let result = tokenizer.read("tolower(ONE) || tocaps(TWO) || contains(a, b) {")

        switch result.expression {
        case let .expression(left, op, right):
            XCTAssertEqual(left.description, "tolower(ONE)")
            XCTAssertEqual(op, "||")
            XCTAssertEqual(right.description, "tocaps(TWO) || contains(a, b)")
        default:
            XCTFail("wrong expression value, found \(String(describing: result.expression))")
        }
        XCTAssertEqual(result.rest, "{")
    }
}
