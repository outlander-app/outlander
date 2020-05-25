//
//  AliasCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Eitan Romanoff on 5/24/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class AliasCommandHandlerTests: XCTestCase {
    
    var handler = AliasCommandHandler()
    var context = GameContext()

    override func setUp() {
    }

    override func tearDown() {
    }

    func test_add() {
        let expectedAliasPattern = "corb"
        let expectedAliasReplace = "charge my camb orb 90"
        let expectedAliasClass = "some class"
        let expectedAliasValue = "#alias {\(expectedAliasPattern)} {\(expectedAliasReplace)} {\(expectedAliasClass)}"
        
        self.context.gags = []
        handler.handle("#alias add {\(expectedAliasPattern)} {\(expectedAliasReplace)} {\(expectedAliasClass)}", with: self.context)
        
        let alias = self.context.aliases[0]
        XCTAssertEqual(alias.pattern, expectedAliasPattern)
        XCTAssertEqual(alias.replace, expectedAliasReplace)
        XCTAssertEqual(alias.className, expectedAliasClass)
        XCTAssertEqual(alias.description, expectedAliasValue)
    }
    
    func test_clear() {
        self.context.aliases = [Alias(pattern: "corb", replace: "charge my camb orb 90", className: "some class")]
        handler.handle("#alias clear", with: self.context)
        XCTAssertEqual(self.context.aliases.count, 0)
    }
}
