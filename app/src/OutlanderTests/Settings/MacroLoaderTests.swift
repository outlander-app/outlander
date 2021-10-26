//
//  MacroLoaderTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 10/25/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import XCTest

class MacroLoaderTests: XCTestCase {
    let fileSystem = InMemoryFileSystem()
    var loader: MacroLoader?
    let context = GameContext()

    override func setUp() {
        loader = MacroLoader(fileSystem)
    }

    func test_load() {
        fileSystem.contentToLoad = "#macro {69} {look}\n#macro {75} {health}"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.macros.count, 2)
    }

    func test_load_modifiers() {
        fileSystem.contentToLoad = "#macro {⌃69} {look}\n#macro {75} {health}"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.macros.count, 2)
        let macro = context.macros["⌃69"]!
        XCTAssertEqual(macro.modifiers.description, "⌃")
        XCTAssertEqual(macro.carbonKeyCode, 69)
    }

    func test_save() {
        fileSystem.contentToLoad = "#macro {69} {look}\n#macro {75} {health}\n"

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, macros: context.macros)

        XCTAssertEqual(fileSystem.savedContent ?? "",
                       """
                       #macro {69} {look}
                       #macro {75} {health}

                       """)
    }

    func test_save_modifiers() {
        fileSystem.contentToLoad = "#macro {⌃69} {look}\n#macro {75} {health}\n"

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, macros: context.macros)

        XCTAssertEqual(fileSystem.savedContent ?? "",
                       """
                       #macro {⌃69} {look}
                       #macro {75} {health}

                       """)
    }

    func test_save_modifiers_sorts_by_keycode() {
        fileSystem.contentToLoad = "#macro {69} {look}\n#macro {⌃75} {health}\n#macro {⌃69} {look}\n#macro {75} {health}\n"

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, macros: context.macros)

        XCTAssertEqual(fileSystem.savedContent ?? "",
                       """
                       #macro {69} {look}
                       #macro {⌃69} {look}
                       #macro {75} {health}
                       #macro {⌃75} {health}

                       """)
    }
}
