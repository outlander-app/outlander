//
//  LogBuilderTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 12/17/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import XCTest

class LogBuilderTestsTests: XCTestCase {
    func test_keeps_thought_stream() {
        let logger = InMemoryLogger()
        let builder = LogBuilder()
        let context = GameContext()
        context.applicationSettings.profile.logging = true
        context.applicationSettings.windowsToLog = ["thoughts"]

        builder.append(TextTag(text: "[General][Char] ", window: "thoughts"), windowName: "thoughts", context: context)
        builder.append(TextTag(text: "Something something.\n", window: "thoughts"), windowName: "thoughts", context: context)

        builder.flush(logger)

        XCTAssertEqual(logger.history.count, 1)
        XCTAssertEqual(logger.history[0], "[STREAM]: [General][Char] Something something.\n")
    }

    func test_skip_repeating_prompts() {
        let logger = InMemoryLogger()
        let builder = LogBuilder()
        let context = GameContext()
        context.applicationSettings.profile.logging = true
        context.applicationSettings.windowsToLog = ["main"]

        builder.append(TextTag(text: ">", window: "main", isPrompt: true), windowName: "main", context: context)
        builder.append(TextTag(text: ">", window: "main", isPrompt: true), windowName: "main", context: context)

        builder.flush(logger)

        XCTAssertEqual(logger.history.count, 1)
        XCTAssertEqual(logger.history[0], "[STREAM]: >")
    }

    func test_logs_player_commands_on_same_line_as_prompt() {
        let logger = InMemoryLogger()
        let builder = LogBuilder()
        let context = GameContext()
        context.applicationSettings.profile.logging = true
        context.applicationSettings.windowsToLog = ["main"]

        builder.append(TextTag(text: ">", window: "main", isPrompt: true), windowName: "main", context: context)
        builder.append(TextTag(text: "something", window: "main", playerCommand: true), windowName: "main", context: context)

        builder.flush(logger)

        XCTAssertEqual(logger.history.count, 1)
        XCTAssertEqual(logger.history[0], "[STREAM]: >something")
    }

    func test_logs_non_player_commands_on_next_line() {
        let logger = InMemoryLogger()
        let builder = LogBuilder()
        let context = GameContext()
        context.applicationSettings.profile.logging = true
        context.applicationSettings.windowsToLog = ["main", "deaths"]

        builder.append(TextTag(text: ">", window: "main", isPrompt: true), windowName: "main", context: context)
        builder.append(TextTag(text: "* Someone was struck down!\n", window: "deaths", playerCommand: false), windowName: "deaths", context: context)

        builder.flush(logger)

        XCTAssertEqual(logger.history.count, 1)
        XCTAssertEqual(logger.history[0], "[STREAM]: >\n* Someone was struck down!\n")
    }

    func test_ignore_repeated_newlines() {
        let logger = InMemoryLogger()
        let builder = LogBuilder()
        let context = GameContext()
        context.applicationSettings.profile.logging = true
        context.applicationSettings.windowsToLog = ["main"]

        builder.append(TextTag(text: "something\n", window: "main", playerCommand: false), windowName: "main", context: context)
        builder.append(TextTag(text: "\n", window: "main", playerCommand: false), windowName: "main", context: context)
        builder.append(TextTag(text: "\n", window: "main", playerCommand: false), windowName: "main", context: context)

        builder.flush(logger)

        XCTAssertEqual(logger.history.count, 1)
        XCTAssertEqual(logger.history[0], "[STREAM]: something\n")
    }
}
