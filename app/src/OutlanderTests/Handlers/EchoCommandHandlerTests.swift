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
        self.context.events = events
    }

    override func tearDown() {
    }

    func test_can_handle_echo() {
        XCTAssertTrue(handler.canHandle(command: "#echo hi"))
    }
    
    func test_can_handle_does_not_match_echo1() {
        XCTAssertFalse(handler.canHandle(command: "#echo1 hi"))
    }

    func test_echo() {
        handler.handle(command: "#echo hi", withContext: self.context)
        
        if let tag = self.events.lastData as? TextTag {
            XCTAssertEqual(tag.text, "hi\n")
            XCTAssertEqual(tag.window, "")
        }
        else {
            XCTFail("Did not recieve a TextTag")
        }
    }

    func test_echo_to_window() {
        handler.handle(command: "#echo >log hi", withContext: self.context)
        
        if let tag = self.events.lastData as? TextTag {
            XCTAssertEqual(tag.text, "hi\n")
            XCTAssertEqual(tag.window, "log")
        }
        else {
            XCTFail("Did not recieve a TextTag")
        }
    }
    
    func test_echo_to_window_with_foreground_only() {
        handler.handle(command: "#echo #000000 hello", withContext: self.context)
        
        if let tag = self.events.lastData as? TextTag {
            XCTAssertEqual(tag.text, "hello\n")
            XCTAssertEqual(tag.window, "")
            XCTAssertEqual(tag.color, "#000000")
            XCTAssertNil(tag.backgroundColor)
        }
        else {
            XCTFail("Did not recieve a TextTag")
        }
    }

    func test_echo_to_window_with_foreground_and_background() {
        handler.handle(command: "#echo #000000,#efefef hello", withContext: self.context)
        
        if let tag = self.events.lastData as? TextTag {
            XCTAssertEqual(tag.text, "hello\n")
            XCTAssertEqual(tag.window, "")
            XCTAssertEqual(tag.color, "#000000")
            XCTAssertEqual(tag.backgroundColor, "#efefef")
        }
        else {
            XCTFail("Did not recieve a TextTag")
        }
    }
    
    func test_echo_to_window_with_everything() {
        handler.handle(command: "#echo >log #000000,#efefef hello", withContext: self.context)

        if let tag = self.events.lastData as? TextTag {
            XCTAssertEqual(tag.text, "hello\n")
            XCTAssertEqual(tag.window, "log")
            XCTAssertEqual(tag.color, "#000000")
            XCTAssertEqual(tag.backgroundColor, "#efefef")
        }
        else {
            XCTFail("Did not recieve a TextTag")
        }
    }
}
