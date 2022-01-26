//
//  WindowCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class WindowCommandHandlerTests: XCTestCase {
    var files = InMemoryFileSystem()
    var handler = WindowCommandHandler(InMemoryFileSystem())
    var events = InMemoryEvents()
    var context = GameContext()

    override func setUp() {
        files = InMemoryFileSystem()
        handler = WindowCommandHandler(files)
        context = GameContext()
        events = InMemoryEvents()
        context.events2 = events
        context.applicationSettings.paths.rootUrl = URL(fileURLWithPath: "/Users/jomc/Documents/Outlander/", isDirectory: true)
    }

    override func tearDown() {}

    func test_can_handle_window_command() {
        XCTAssertTrue(handler.canHandle("#window list"))
    }

    func test_can_handle_does_not_match_window1() {
        XCTAssertFalse(handler.canHandle("#window1 hi"))
    }

    func test_handles_list_command() {
        handler.handle("#window list", with: context)

        if let data = events.lastData as? WindowCommandEvent {
            XCTAssertEqual(data.action, "list")
            XCTAssertEqual(data.window, "")
        } else {
            XCTFail("Did not recieve data")
        }
    }

    func test_handles_reload_command() {
        files.contentToLoad = "{}"
        handler.handle("#window reload", with: context)

        if let data = events.lastData as? WindowCommandEvent {
            XCTAssertEqual(data.action, "reload")
            XCTAssertEqual(data.window, "")
        } else {
            XCTFail("Did not recieve data")
        }
    }

    func test_handles_add_command() {
        handler.handle("#window add log", with: context)

        if let data = events.lastData as? WindowCommandEvent {
            XCTAssertEqual(data.action, "add")
            XCTAssertEqual(data.window, "log")
        } else {
            XCTFail("Did not recieve data")
        }
    }

    func test_handles_show_command() {
        handler.handle("#window show log", with: context)

        if let data = events.lastData as? WindowCommandEvent {
            XCTAssertEqual(data.action, "show")
            XCTAssertEqual(data.window, "log")
        } else {
            XCTFail("Did not recieve data")
        }
    }

    func test_handles_hide_command() {
        handler.handle("#window hide log", with: context)

        if let data = events.lastData as? WindowCommandEvent {
            XCTAssertEqual(data.action, "hide")
            XCTAssertEqual(data.window, "log")
        } else {
            XCTFail("Did not recieve data")
        }
    }
}
