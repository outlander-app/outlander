//
//  ClassLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/9/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class ClassLoaderTests: XCTestCase {
    let fileSystem = InMemoryFileSystem()
    var loader: ClassLoader?
    let context = GameContext()

    override func setUp() {
        loader = ClassLoader(fileSystem)
    }

    func test_load() {
        fileSystem.contentToLoad = "#class {app} {off}\n#class {combat} {on}"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.classes.all().count, 2)

        let app = context.classes.all()[0]
        XCTAssertEqual(app.key, "app")
        XCTAssertFalse(app.value)

        let combat = context.classes.all()[1]
        XCTAssertEqual(combat.key, "combat")
        XCTAssertTrue(combat.value)
    }

    func test_save() {
        fileSystem.contentToLoad = "#class {app} {off}\n#class {combat} {on}"

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, classes: context.classes)

        XCTAssertEqual(fileSystem.savedContent ?? "",
                       """
                       #class {app} {off}
                       #class {combat} {on}

                       """)
    }
}
