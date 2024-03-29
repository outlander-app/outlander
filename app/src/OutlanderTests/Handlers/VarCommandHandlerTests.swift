//
//  VarCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class VarCommandHandlerTests: XCTestCase {
    var handler = VarCommandHandler(InMemoryFileSystem())
    var context = GameContext()

    override func setUp() {}

    override func tearDown() {}

    func test_basic() {
        handler.handle("#var one two", with: context)
        XCTAssertEqual(context.globalVars["one"], "two")
    }

    func test_multi_value() {
        handler.handle("#var one two three", with: context)
        XCTAssertEqual(context.globalVars["one"], "two three")
    }

    func test_identifier_value() {
        handler.handle("#var one.two three four", with: context)
        XCTAssertEqual(context.globalVars["one.two"], "three four")
    }

    func test_no_value_sets_empty() {
        handler.handle("#var empty", with: context)
        XCTAssertEqual(context.globalVars["empty"], "")
    }
}
