//
//  AliasLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class AliasLoaderTests: XCTestCase {
    let fileSystem = InMemoryFileSystem()
    var loader: AliasLoader?
    let context = GameContext()

    override func setUp() {
        loader = AliasLoader(fileSystem)
    }

    func test_load() {
        fileSystem.contentToLoad = """
        #alias {cr} {.collect rock maxexp $0}
        #alias {ss} {stance set 100 1 94} {a class}

        """

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.aliases.count, 2)
        XCTAssertEqual(context.aliases[1].pattern, "ss")
        XCTAssertEqual(context.aliases[1].replace, "stance set 100 1 94")
        XCTAssertEqual(context.aliases[1].className, "a class")
    }

    func test_save() {
        fileSystem.contentToLoad = """
        #alias {cr} {.collect rock maxexp $0}
        #alias {ss} {stance set 100 1 94} {a class}

        """

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, aliases: context.aliases)

        XCTAssertEqual(fileSystem.savedContent ?? "",
                       """
                       #alias {cr} {.collect rock maxexp $0}
                       #alias {ss} {stance set 100 1 94} {a class}

                       """)
    }

    func test_add() {
        var aliasToAdd = "#alias {corb} {charge my camb orb 90} {a class}"
        let alias = Alias.from(alias: &aliasToAdd)!
        context.addAlias(alias: alias)
        loader!.save(context.applicationSettings, aliases: context.aliases)

        XCTAssertEqual(fileSystem.savedContent ?? "",
                       """
                       #alias {corb} {charge my camb orb 90} {a class}

                       """)
    }
}
