//
//  SubstituteLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class SubstituteLoaderTests: XCTestCase {

    let fileSystem = InMemoryFileSystem()
    var loader: SubstituteLoader?
    let context = GameContext()

    override func setUp() {
        self.loader = SubstituteLoader(fileSystem)
    }

    func test_load() {
        self.fileSystem.contentToLoad =
"""
#subs {^(From the progress so far, it looks like .* (?:is|are)(?: of | )practically worthless.)} {$1(1/13)} {analyze}
#subs {blinding mana to the} {blinding mana (21/21) to the}

"""

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.substitutes.count, 2)

        var sub = context.substitutes[0]
        XCTAssertEqual(sub.pattern, "^(From the progress so far, it looks like .* (?:is|are)(?: of | )practically worthless.)")
        XCTAssertEqual(sub.action, "$1(1/13)")
        XCTAssertEqual(sub.className, "analyze")

        sub = context.substitutes[1]
        XCTAssertEqual(sub.pattern, "blinding mana to the")
        XCTAssertEqual(sub.action, "blinding mana (21/21) to the")
        XCTAssertEqual(sub.className, "")
    }

    func test_save() {
        self.fileSystem.contentToLoad =
"""
#subs {^(From the progress so far, it looks like .* (?:is|are)(?: of | )practically worthless.)} {$1(1/13)} {analyze}
#subs {blinding mana to the} {blinding mana (21/21) to the}

"""

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, subsitutes: context.substitutes)

        XCTAssertEqual(self.fileSystem.savedContent ?? "",
"""
#subs {^(From the progress so far, it looks like .* (?:is|are)(?: of | )practically worthless.)} {$1(1/13)} {analyze}
#subs {blinding mana to the} {blinding mana (21/21) to the}

""")
        
    }
}
