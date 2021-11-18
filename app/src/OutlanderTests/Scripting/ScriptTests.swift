//
//  ScriptTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class ScriptTests: XCTestCase {
    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testCanReadBasicScript() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([])
        XCTAssertEqual(script.context.lines.count, 2)
        XCTAssertEqual(script.context.labels.count, 1)
    }

    func testCanIncludeOtherScripts() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["include util.cmd", "mylabel:", "  echo hello"]
        loader.lines["util.cmd"] = ["something:", "  echo something"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([])
        XCTAssertEqual(script.context.lines.count, 4)
        XCTAssertEqual(script.context.labels.count, 2)
    }

    func testCannotIncludeItself() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["include forage.cmd", "mylabel:", "  echo hello"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([])
        XCTAssertEqual(script.context.lines.count, 2)
        XCTAssertEqual(script.context.labels.count, 1)
    }

    func testReplacesExistingLabelsWhenIncludingOtherScripts() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["include util.cmd", "alabel:", "  echo hello"]
        loader.lines["util.cmd"] = ["alabel:", "  echo something"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([])
        XCTAssertEqual(script.context.lines.count, 4)
        XCTAssertEqual(script.context.labels.count, 1)
    }

    func testStuff() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run([])
    }
    
    func test_argument_shift() throws {
        let context = GameContext()
        let loader = InMemoryScriptLoader()
        loader.lines["forage.cmd"] = ["mylabel:", "  echo hello"]
        let script = try Script("forage.cmd", loader: loader, gameContext: context)
        script.run(["one", "two"])
        XCTAssertEqual(script.context.args, ["one", "two"])
        XCTAssertEqual(script.context.argumentVars, ["0":"one two", "1": "one","2": "two"])

        script.context.shiftArgs()
        XCTAssertEqual(script.context.args, ["two"])
        XCTAssertEqual(script.context.argumentVars, ["0":"two", "1": "two"])

        script.context.shiftArgs()
        XCTAssertEqual(script.context.args, [])
        XCTAssertEqual(script.context.argumentVars, [:])

        script.context.shiftArgs()
        XCTAssertEqual(script.context.args, [])
        XCTAssertEqual(script.context.argumentVars, [:])
    }
}
