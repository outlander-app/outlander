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
        self.fileSystem.contentToLoad = "#var {Alchemy.LearningRate} {0}\n#var {Alchemy.LearningRateName} {clear}\n"

        loader!.load(context.applicationSettings, context: context)

        XCTAssertEqual(context.globalVars.count, 8)
        XCTAssertEqual(context.globalVars["Alchemy.LearningRate"], "0")
        XCTAssertEqual(context.globalVars["Alchemy.LearningRateName"], "clear")
    }

    func test_save() {
        self.fileSystem.contentToLoad = "#var {Alchemy.LearningRate} {0}\n#var {Alchemy.LearningRateName} {clear}\n"

        loader!.load(context.applicationSettings, context: context)
        loader!.save(context.applicationSettings, variables: context.globalVars)
        
        XCTAssertEqual(self.fileSystem.savedContent ?? "",
                       """
#var {Alchemy.LearningRate} {0}
#var {Alchemy.LearningRateName} {clear}
#var {lefthand} {Empty}
#var {preparedspell} {None}
#var {prompt} {>}
#var {righthand} {Empty}
#var {roundtime} {0}
#var {tdp} {0}

""")
    }
}
