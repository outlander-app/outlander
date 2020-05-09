//
//  WindowCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

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
