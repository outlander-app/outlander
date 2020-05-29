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
    }
}
