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
        XCTAssertTrue(handler.canHandle("#window list"))
    }
    
    func test_can_handle_does_not_match_window1() {
        XCTAssertFalse(handler.canHandle("#window1 hi"))
    }
    
    func test_handles_list_command() {
        handler.handle("#window list", with: self.context)
        
        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "list")
            XCTAssertEqual(data["window"], "")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }
    
    func test_handles_reload_command() {
        handler.handle("#window reload", with: self.context)
        
        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "reload")
            XCTAssertEqual(data["window"], "")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }
    
    func test_handles_add_command() {
        handler.handle("#window add log", with: self.context)
        
        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "add")
            XCTAssertEqual(data["window"], "log")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }
    
    func test_handles_show_command() {
        handler.handle("#window show log", with: self.context)
        
        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "show")
            XCTAssertEqual(data["window"], "log")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }
    
    func test_handles_hide_command() {
        handler.handle("#window hide log", with: self.context)
        
        if let data = self.events.lastData as? [String:String] {
            XCTAssertEqual(data["action"], "hide")
            XCTAssertEqual(data["window"], "log")
        }
        else {
            XCTFail("Did not recieve data")
        }
    }
}
