//
//  TriggerLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class TriggerLoaderTests: XCTestCase {
    let fileSystem = InMemoryFileSystem()
    var loader: TriggerLoader?
    let context = GameContext()

    override func setUp() {
        loader = TriggerLoader(fileSystem)
    }

    func test_load() {
        fileSystem.contentToLoad =
            """
            #trigger {^You feel like now might be a good time to change the bandages on your (\\w.+).$} {#echo >log Change your $1 bandages.}
            #trigger {An iron portcullis is raised, heralding the} {#send watch} {combat}

            """

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.triggers.count, 2)

        var sub = context.triggers[0]
        XCTAssertEqual(sub.pattern, "^You feel like now might be a good time to change the bandages on your (\\w.+).$")
        XCTAssertEqual(sub.action, "#echo >log Change your $1 bandages.")
        XCTAssertEqual(sub.className, "")

        sub = context.triggers[1]
        XCTAssertEqual(sub.pattern, "An iron portcullis is raised, heralding the")
        XCTAssertEqual(sub.action, "#send watch")
        XCTAssertEqual(sub.className, "combat")
    }

    func test_save() {
        fileSystem.contentToLoad =
            """
            #trigger {^You feel like now might be a good time to change the bandages on your (\\w.+).$} {#echo >log Change your $1 bandages.}
            #trigger {An iron portcullis is raised, heralding the} {#send watch} {combat}

            """

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, triggers: context.triggers)

        XCTAssertEqual(fileSystem.savedContent ?? "", fileSystem.contentToLoad!)
    }
}
