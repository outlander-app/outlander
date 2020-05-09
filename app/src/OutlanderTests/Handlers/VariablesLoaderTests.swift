//
//  VariablesLoaderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class VariablesLoaderTests: XCTestCase {
    
    let fileSystem = InMemoryFileSystem()
    var loader: VariablesLoader?
    let context = GameContext()

    override func setUp() {
        self.loader = VariablesLoader(fileSystem)
    }

    func test_load() {
        self.fileSystem.contentToLoad = "#var {Alchemy.LearningRate} {0}\n#var {Alchemy.LearningRateName} {clear}"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.globalVars.count, 2)
        XCTAssertEqual(context.globalVars["Alchemy.LearningRate"], "0")
        XCTAssertEqual(context.globalVars["Alchemy.LearningRateName"], "clear")
    }
}
