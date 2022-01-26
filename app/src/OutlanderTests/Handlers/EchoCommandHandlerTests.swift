//
//  EchoCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class EchoCommandHandlerTests: XCTestCase {
    let handler = EchoCommandHandler()
    let context = GameContext()
    let events = InMemoryEvents()

    override func setUp() {
        context.events2 = events
    }

    override func tearDown() {}

    func test_can_handle_echo() {
        XCTAssertTrue(handler.canHandle("#echo hi"))
    }

    func test_can_handle_does_not_match_echo1() {
        XCTAssertFalse(handler.canHandle("#echo1 hi"))
    }

    func test_echo() {
        handler.handle("#echo hi", with: context)

        if let tag = events.lastData as? EchoTagEvent {
            XCTAssertEqual(tag.tag.text, "hi\n")
            XCTAssertEqual(tag.tag.window, "")
        } else {
            XCTFail("Did not recieve a TextTag")
        }
    }

    func test_echo_to_window() {
        handler.handle("#echo >log hi", with: context)

        if let tag = events.lastData as? EchoTagEvent {
            XCTAssertEqual(tag.tag.text, "hi\n")
            XCTAssertEqual(tag.tag.window, "log")
        } else {
            XCTFail("Did not recieve a TextTag")
        }
    }

    func test_echo_to_window_with_foreground_only() {
        handler.handle("#echo #000000 hello", with: context)

        if let tag = events.lastData as? EchoTagEvent {
            XCTAssertEqual(tag.tag.text, "hello\n")
            XCTAssertEqual(tag.tag.window, "")
            XCTAssertEqual(tag.tag.color, "#000000")
            XCTAssertNil(tag.tag.backgroundColor)
        } else {
            XCTFail("Did not recieve a TextTag")
        }
    }

    func test_echo_to_window_with_foreground_and_background() {
        handler.handle("#echo #000000,#efefef hello", with: context)

        if let tag = events.lastData as? EchoTagEvent {
            XCTAssertEqual(tag.tag.text, "hello\n")
            XCTAssertEqual(tag.tag.window, "")
            XCTAssertEqual(tag.tag.color, "#000000")
            XCTAssertEqual(tag.tag.backgroundColor, "#efefef")
        } else {
            XCTFail("Did not recieve a TextTag")
        }
    }

    func test_echo_to_window_with_everything() {
        handler.handle("#echo >log #000000,#efefef hello", with: context)

        if let tag = events.lastData as? EchoTagEvent {
            XCTAssertEqual(tag.tag.text, "hello\n")
            XCTAssertEqual(tag.tag.window, "log")
            XCTAssertEqual(tag.tag.color, "#000000")
            XCTAssertEqual(tag.tag.backgroundColor, "#efefef")
        } else {
            XCTFail("Did not recieve a TextTag")
        }
    }

    func test_echo_exp() {
        handler.handle("#echo >experience #cccccc        Appraisal:  243 66%  (16/34)  0.00", with: context)

        if let tag = events.lastData as? EchoTagEvent {
            XCTAssertEqual(tag.tag.text, "       Appraisal:  243 66%  (16/34)  0.00\n")
            XCTAssertEqual(tag.tag.window, "experience")
            XCTAssertEqual(tag.tag.color, "#cccccc")
        } else {
            XCTFail("Did not recieve a TextTag")
        }
    }
}
