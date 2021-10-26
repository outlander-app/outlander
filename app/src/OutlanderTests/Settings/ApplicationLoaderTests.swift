//
//  ApplicationLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/22/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class ApplicationLoaderTests: XCTestCase {
    let fileSystem = InMemoryFileSystem()
    var loader: ApplicationLoader?
    let context = GameContext()

    override func setUp() {
        loader = ApplicationLoader(fileSystem)
    }

    func test_load() {
        fileSystem.contentToLoad = """
        {
          "variableTimeFormat" : "hh:mm:ss",
          "defaultProfile" : "Testing",
          "variableDatetimeFormat" : "yyyy-MM-dd hh:mm:ss",
          "checkForApplicationUpdates" : "yes",
          "downloadPreReleaseVersions" : "no",
          "variableDateFormat" : "MM-dd-yyyy"
        }
        """

        loader!.load(context.applicationSettings.paths, context: context)

        XCTAssertEqual(context.applicationSettings.profile.name, "Testing")
        XCTAssertTrue(context.applicationSettings.checkForApplicationUpdates)
        XCTAssertFalse(context.applicationSettings.downloadPreReleaseVersions)
        XCTAssertEqual(context.applicationSettings.variableDateFormat, "MM-dd-yyyy")
        XCTAssertEqual(context.applicationSettings.variableTimeFormat, "hh:mm:ss")
        XCTAssertEqual(context.applicationSettings.variableDatetimeFormat, "yyyy-MM-dd hh:mm:ss")
        XCTAssertEqual(context.applicationSettings.authenticationServerAddress, "eaccess.play.net")
        XCTAssertEqual(context.applicationSettings.authenticationServerPort, UInt16(7910))
    }

    func test_load_with_server_settings() {
        fileSystem.contentToLoad = """
        {
          "variableTimeFormat" : "hh:mm:ss",
          "defaultProfile" : "Testing",
          "variableDatetimeFormat" : "yyyy-MM-dd hh:mm:ss",
          "checkForApplicationUpdates" : "yes",
          "downloadPreReleaseVersions" : "no",
          "variableDateFormat" : "MM-dd-yyyy",
          "authenticationServerAddress" : "eaccess.play.net2",
          "authenticationServerPort" : 8190
        }
        """

        loader!.load(context.applicationSettings.paths, context: context)

        XCTAssertEqual(context.applicationSettings.profile.name, "Testing")
        XCTAssertTrue(context.applicationSettings.checkForApplicationUpdates)
        XCTAssertFalse(context.applicationSettings.downloadPreReleaseVersions)
        XCTAssertEqual(context.applicationSettings.variableDateFormat, "MM-dd-yyyy")
        XCTAssertEqual(context.applicationSettings.variableTimeFormat, "hh:mm:ss")
        XCTAssertEqual(context.applicationSettings.variableDatetimeFormat, "yyyy-MM-dd hh:mm:ss")
        XCTAssertEqual(context.applicationSettings.authenticationServerAddress, "eaccess.play.net2")
        XCTAssertEqual(context.applicationSettings.authenticationServerPort, UInt16(8190))
    }
}
