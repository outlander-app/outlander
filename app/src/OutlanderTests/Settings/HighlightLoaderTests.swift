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
        self.loader = HighlightLoader(fileSystem)
    }
    
    func test_load() {
        self.fileSystem.contentToLoad = """
#highlight {#0000FF} {^(You've gained a new rank.*)$}
#highlight {#33FF08} {\\bcard\\b} {some class}
#highlight {#9CA510} {dragonwood}
#highlight {#296B00, #efefef} {Legend} {} {wow.mp3}

"""

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.highlights.count, 4)
        XCTAssertEqual(context.highlights[1].foreColor, "#33ff08")
        XCTAssertEqual(context.highlights[1].pattern, "\\bcard\\b")
        XCTAssertEqual(context.highlights[1].className, "some class")

        let legend = context.highlights[3]
        XCTAssertEqual(legend.foreColor, "#296b00")
        XCTAssertEqual(legend.backgroundColor, "#efefef")
        XCTAssertEqual(legend.pattern, "Legend")
        XCTAssertEqual(legend.className, "")
        XCTAssertEqual(legend.soundFile, "wow.mp3")
    }
    
    func test_save() {
        self.fileSystem.contentToLoad = """
#highlight {#0000ff} {^(You've gained a new rank.*)$}
#highlight {#33FF08} {\\bcard\\b} {some class}
#highlight {#9CA510} {dragonwood}
#highlight {#296B00, #efefef} {Legend} {} {wow.mp3}

"""

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, highlights: context.highlights)

        XCTAssertEqual(self.fileSystem.savedContent ?? "",
                       """
#highlight {#0000ff} {^(You've gained a new rank.*)$}
#highlight {#33ff08} {\\bcard\\b} {some class}
#highlight {#9ca510} {dragonwood}
#highlight {#296b00,#efefef} {Legend} {} {wow.mp3}

""")
    }
}
