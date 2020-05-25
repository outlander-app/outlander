//
//  GagLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class GagLoaderTests: XCTestCase {

    let fileSystem = InMemoryFileSystem()
    var loader: GagLoader?
    let context = GameContext()
    
    override func setUp() {
        self.loader = GagLoader(fileSystem)
    }

    func test_load() {
        self.fileSystem.contentToLoad = "#gag {Guard Report} {a class}\n#gag {coins into the Darkbox and reaches inside it}\n"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.gags.count, 2)
    }

    func test_save() {
        self.fileSystem.contentToLoad = "#gag {Guard Report} {a class}\n#gag {coins into the Darkbox and reaches inside it}\n"

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, gags: context.gags)

        XCTAssertEqual(self.fileSystem.savedContent ?? "",
                       """
#gag {Guard Report} {a class}
#gag {coins into the Darkbox and reaches inside it}

""")
    }
    
    func test_add() {
        var gagToAdd = "#gag {Guard Report} {a class}"
        context.addGag(gag: &gagToAdd)
        loader!.save(context.applicationSettings, gags: context.gags)
        
        XCTAssertEqual(self.fileSystem.savedContent ?? "",
                       """
#gag {Guard Report} {a class}

""")
    }
}
