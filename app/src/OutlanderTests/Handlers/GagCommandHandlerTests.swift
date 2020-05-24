//
//  GagCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Eitan Romanoff on 5/24/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class GagCommandHandlerTests: XCTestCase {
    
    var handler = GagCommandHandler()
    var context = GameContext()

    override func setUp() {
    }

    override func tearDown() {
    }

    func test_add() {
        let expectedGagPattern = "^Also here.*$"
        let expectedGagClass = "some class"
        let expectedGagStrValue = "#gag {\(expectedGagPattern)} {\(expectedGagClass)}"
        
        self.context.gags = []
        handler.handle("#gag add {\(expectedGagPattern)} {\(expectedGagClass)}", with: self.context)
        
        let gag = self.context.gags[0]
        XCTAssertEqual(gag.pattern, expectedGagPattern)
        XCTAssertEqual(gag.className, expectedGagClass)
        XCTAssertEqual(gag.description, expectedGagStrValue)
    }
    
    func test_clear() {
        self.context.gags = [Gag(pattern: "^Also here.*$", className: "some class")]
        handler.handle("#gag clear", with: self.context)
        XCTAssertEqual(self.context.gags.count, 0)
    }
}
