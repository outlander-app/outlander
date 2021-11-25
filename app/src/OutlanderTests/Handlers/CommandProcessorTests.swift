//
//  CommandProcessorTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/25/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class CommandProcessorTests: XCTestCase {
    var processor = CommandProcesssor(InMemoryFileSystem(), pluginManager: InMemoryPluginManager())
    var context = GameContext(InMemoryEvents())

    var events: InMemoryEvents {
        context.events as! InMemoryEvents
    }

    func test_alias_replacement_1() {
        context.aliases.append(Alias(pattern: "=", replace: "#send $0"))

        let result = processor.processAliases("= one two", with: context)

        XCTAssertEqual(result, "#send one two")
    }

    func test_alias_replace_non_used_args_with_empty() {
        context.aliases.append(Alias(pattern: "=", replace: "#send $0"))

        let result = processor.processAliases("=", with: context)

        XCTAssertEqual(result, "#send ")
    }

    func test_alias_replacement_2() {
        context.aliases.append(Alias(pattern: "=", replace: "#send $2"))

        let result = processor.processAliases("= one two", with: context)

        XCTAssertEqual(result, "#send two")
    }

    func test_alias_replacement_3() {
        context.aliases.append(Alias(pattern: "l2", replace: "load arrows"))

        let result = processor.processAliases("l2", with: context)

        XCTAssertEqual(result, "load arrows")
    }

    func test_zero_aliases_returns_text() {
        let result = processor.processAliases("l2", with: context)

        XCTAssertEqual(result, "l2")
    }
}
