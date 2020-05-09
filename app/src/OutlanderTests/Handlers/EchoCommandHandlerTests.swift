//
//  EchoCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class InMemoryEvents : Events {
    public var lastData: Any?

    func post(_ channel: String, data: Any?) {
        self.lastData = data
    }

    func handle(_ target: AnyObject, channel: String, handler: @escaping (Any?) -> Void) {
    }
    
    func unregister(_ target: AnyObject) {
    }
}

class WindowCommandHandlerTests: XCTestCase {
    
    let handler = WindowCommandHandler()
    let context = GameContext()
    let events = InMemoryEvents()

    override func setUp() {
        self.context.events = self.events
        self.context.applicationSettings.paths.rootUrl = URL(fileURLWithPath: "/Users/jomc/Documents/Outlander/", isDirectory: true)
    }
    
    override func tearDown() {
    }
    
    func test_can_handle_window_command() {
        XCTAssertTrue(handler.canHandle(command: "#window list"))
    }
    
    func test_can_handle_does_not_match_window1() {
        XCTAssertFalse(handler.canHandle(command: "#window1 hi"))
    }

    func test_handles_list_command() {
        handler.handle(command: "#window list", withContext: self.context)

        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "list")
            XCTAssertEqual(data["window"], "")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }

    func test_handles_reload_command() {
        handler.handle(command: "#window reload", withContext: self.context)

        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "reload")
            XCTAssertEqual(data["window"], "")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }
    
    func test_handles_add_command() {
        handler.handle(command: "#window add log", withContext: self.context)
        
        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "add")
            XCTAssertEqual(data["window"], "log")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }
    
    func test_handles_show_command() {
        handler.handle(command: "#window show log", withContext: self.context)
        
        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "show")
            XCTAssertEqual(data["window"], "log")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }
    
    func test_handles_hide_command() {
        handler.handle(command: "#window hide log", withContext: self.context)
        
        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "hide")
            XCTAssertEqual(data["window"], "log")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }
}

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
