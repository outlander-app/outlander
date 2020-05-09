//
//  VarCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class VarCommandHandlerTests: XCTestCase {
    
    var handler = VarCommandHandler()
    var context = GameContext()

    override func setUp() {
    }

    override func tearDown() {
    }

    func test_basic() {
        handler.handle(command: "#var one two", withContext: self.context)
        XCTAssertEqual(self.context.globalVars["one"], "two")
    }
    
    func test_multi_value() {
        handler.handle(command: "#var one two three", withContext: self.context)
        XCTAssertEqual(self.context.globalVars["one"], "two three")
    }

    func test_identifier_value() {
        handler.handle(command: "#var one.two three four", withContext: self.context)
        XCTAssertEqual(self.context.globalVars["one.two"], "three four")
    }
}
