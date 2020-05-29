//
//  ProfileConfigLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/22/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class ProfileConfigLoaderTests: XCTestCase {
    let fileSystem = InMemoryFileSystem()
    var loader: ProfileConfigLoader?
    let context = GameContext()

    override func setUp() {
        loader = ProfileConfigLoader(fileSystem)
    }

    func test_load() {
        fileSystem.contentToLoad = """
        Account: AnAccount
        Game: DR
        Character: MyCharacter
        Logging: yes
        RawLogging: no
        Layout: mobile.cfg
        """

        context.applicationSettings.profile.name = "Default"

        loader!.load(context)

        XCTAssertEqual(context.applicationSettings.profile.account, "AnAccount")
        XCTAssertEqual(context.applicationSettings.profile.game, "DR")
        XCTAssertEqual(context.applicationSettings.profile.character, "MyCharacter")
        XCTAssertTrue(context.applicationSettings.profile.logging)
        XCTAssertFalse(context.applicationSettings.profile.rawLogging)
        XCTAssertEqual(context.applicationSettings.profile.layout, "mobile.cfg")
    }
}
