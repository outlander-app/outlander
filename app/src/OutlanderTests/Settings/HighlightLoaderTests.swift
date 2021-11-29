//
//  HighlightLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class HighlightLoaderTests: XCTestCase {
    let fileSystem = InMemoryFileSystem()
    var loader: HighlightLoader?
    let context = GameContext()

    override func setUp() {
        loader = HighlightLoader(fileSystem)
    }

    func test_load() {
        fileSystem.contentToLoad = """
        #highlight {#0000FF} {^(You've gained a new rank.*)$}
        #highlight {#33FF08} {\\bcard\\b} {some class}
        #highlight {#9CA510} {dragonwood}
        #highlight {#296B00, #efefef} {Legend} {} {wow.mp3}

        """

        loader!.load(context.applicationSettings, context: context)

        let hl = context.highlights.all().dropFirst(1).first!

        XCTAssertEqual(context.highlights.count, 4)
        XCTAssertEqual(hl.foreColor, "#33ff08")
        XCTAssertEqual(hl.pattern, "\\bcard\\b")
        XCTAssertEqual(hl.className, "some class")

        let legend = context.highlights.all().dropFirst(3).first!
        XCTAssertEqual(legend.foreColor, "#296b00")
        XCTAssertEqual(legend.backgroundColor, "#efefef")
        XCTAssertEqual(legend.pattern, "Legend")
        XCTAssertEqual(legend.className, "")
        XCTAssertEqual(legend.soundFile, "wow.mp3")
    }

    func test_save() {
        fileSystem.contentToLoad = """
        #highlight {#0000ff} {^(You've gained a new rank.*)$}
        #highlight {#33FF08} {\\bcard\\b} {some class}
        #highlight {#9CA510} {dragonwood}
        #highlight {#296B00, #efefef} {Legend} {} {wow.mp3}

        """

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, highlights: context.highlights.all())

        XCTAssertEqual(fileSystem.savedContent ?? "",
                       """
                       #highlight {#0000ff} {^(You've gained a new rank.*)$}
                       #highlight {#33ff08} {\\bcard\\b} {some class}
                       #highlight {#9ca510} {dragonwood}
                       #highlight {#296b00,#efefef} {Legend} {} {wow.mp3}

                       """)
    }
}
