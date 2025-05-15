//
//  LayoutCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 5/15/25.
//  Copyright © 2025 Joe McBride. All rights reserved.
//

import Foundation
import XCTest

class LayoutCommandHandlerTests: XCTestCase {
    var handler: LayoutCommandHandler?
    let context = GameContext()
    let events = InMemoryEvents()
    let fileSystem = InMemoryFileSystem()

    override func setUp() {
        context.events2 = events
        handler = LayoutCommandHandler(fileSystem)
    }

    override func tearDown() {}

    func test_can_handle_layout() {
        XCTAssertTrue(handler!.canHandle("#layout"))
    }

    func test_default_load() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = true

        handler!.handle("#layout load", with: context)

        if let evt = events.history.first as? LoadLayoutEvent {
            XCTAssertEqual(evt.layout, "default.cfg")
        } else {
            XCTFail("Did not recieve a LoadLayoutEvent")
        }

        if let evt = events.history.last as? EchoTextEvent {
            XCTAssertEqual(evt.text, "Loaded layout: default.cfg\n")
        } else {
            XCTFail("Did not recieve a EchoTextEvent")
        }
    }

    func test_default_save() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = true

        handler!.handle("#layout save", with: context)

        if let evt = events.history.first as? SaveLayoutEvent {
            XCTAssertEqual(evt.layout, "default.cfg")
        } else {
            XCTFail("Did not recieve a SaveLayoutEvent")
        }

        if let evt = events.history.last as? EchoTextEvent {
            XCTAssertEqual(evt.text, "Saved layout: default.cfg\n")
        } else {
            XCTFail("Did not recieve a EchoTextEvent")
        }
    }
    
    func test_named_load() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = true

        handler!.handle("#layout load other.cfg", with: context)

        if let evt = events.history.first as? LoadLayoutEvent {
            XCTAssertEqual(evt.layout, "other.cfg")
        } else {
            XCTFail("Did not recieve a LoadLayoutEvent")
        }

        if let evt = events.history.last as? EchoTextEvent {
            XCTAssertEqual(evt.text, "Loaded layout: other.cfg\n")
        } else {
            XCTFail("Did not recieve a EchoTextEvent")
        }
    }

    func test_named_save() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = true

        handler!.handle("#layout save other.cfg", with: context)

        if let evt = events.history.first as? SaveLayoutEvent {
            XCTAssertEqual(evt.layout, "other.cfg")
        } else {
            XCTFail("Did not recieve a SaveLayoutEvent")
        }

        if let evt = events.history.last as? EchoTextEvent {
            XCTAssertEqual(evt.text, "Saved layout: other.cfg\n")
        } else {
            XCTFail("Did not recieve a EchoTextEvent")
        }
    }

    func test_named_save_file_does_not_exist() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = false

        handler!.handle("#layout save other.cfg", with: context)

        if let evt = events.history.first as? SaveLayoutEvent {
            XCTAssertEqual(evt.layout, "other.cfg")
        } else {
            XCTFail("Did not recieve a SaveLayoutEvent")
        }

        if let evt = events.history.last as? EchoTextEvent {
            XCTAssertEqual(evt.text, "Saved layout: other.cfg\n")
        } else {
            XCTFail("Did not recieve a EchoTextEvent")
        }
    }

    func test_named_without_suffix_load() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = true

        handler!.handle("#layout load other", with: context)

        if let evt = events.history.first as? LoadLayoutEvent {
            XCTAssertEqual(evt.layout, "other.cfg")
        } else {
            XCTFail("Did not recieve a LoadLayoutEvent")
        }

        if let evt = events.history.last as? EchoTextEvent {
            XCTAssertEqual(evt.text, "Loaded layout: other.cfg\n")
        } else {
            XCTFail("Did not recieve a EchoTextEvent")
        }
    }

    func test_named_without_suffix_save() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = true

        handler!.handle("#layout save other", with: context)

        if let evt = events.history.first as? SaveLayoutEvent {
            XCTAssertEqual(evt.layout, "other.cfg")
        } else {
            XCTFail("Did not recieve a SaveLayoutEvent")
        }

        if let evt = events.history.last as? EchoTextEvent {
            XCTAssertEqual(evt.text, "Saved layout: other.cfg\n")
        } else {
            XCTFail("Did not recieve a EchoTextEvent")
        }
    }

    func test_file_error_load() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = false

        handler!.handle("#layout load other.cfg", with: context)

        if let evt = events.history.last as? ErrorEvent {
            XCTAssertEqual(evt.error, "Layout 'other.cfg' does not exist\n")
        } else {
            XCTFail("Did not recieve a ErrorEvent")
        }
    }

    func test_file_does_not_error_save() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = false

        handler!.handle("#layout save other.cfg", with: context)

        if let evt = events.history.last as? ErrorEvent {
            XCTFail("Should not be an error")
        }
    }

    func test_default_to_load_if_not_explicit() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = true

        handler!.handle("#layout other", with: context)

        if let evt = events.history.first as? LoadLayoutEvent {
            XCTAssertEqual(evt.layout, "other.cfg")
        } else {
            XCTFail("Did not recieve a LoadLayoutEvent")
        }

        if let evt = events.history.last as? EchoTextEvent {
            XCTAssertEqual(evt.text, "Loaded layout: other.cfg\n")
        } else {
            XCTFail("Did not recieve a EchoTextEvent")
        }
    }

    func test_file_error_defaulting_to_load() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = false

        handler!.handle("#layout other", with: context)

        if let evt = events.history.first as? ErrorEvent {
            XCTAssertEqual(evt.error, "Layout 'other.cfg' does not exist\n")
        } else {
            XCTFail("Did not recieve a ErrorEvent")
        }
    }

    func test_toggle_layout_settings() {
        context.applicationSettings.profile.layout = "default.cfg"
        fileSystem.doesFileExist = false

        handler!.handle("#layout settings", with: context)

        if events.history.first is ToggleLayoutSettingsEvent {
            XCTAssertTrue(true)
        } else {
            XCTFail("Did not recieve a ToggleLayoutSettingsEvent")
        }
    }
}
