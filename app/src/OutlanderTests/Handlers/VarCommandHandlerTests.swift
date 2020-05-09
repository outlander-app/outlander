//
//  VarCommandHandlerTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class VarCommandHandlerTests: XCTestCase {
    
    var handler = VarCommandHandler()
    var context = GameContext()

    override func setUp() {
    }

    override func tearDown() {
    }

    func test_basic() {
        handler.handle(command: "#var one two", withContext: self.context)
        XCTAssertEqual(self.context.globalVars["one"], "two")
    }
    
    func test_multi_value() {
        handler.handle(command: "#var one two three", withContext: self.context)
        XCTAssertEqual(self.context.globalVars["one"], "two three")
    }
    
    func test_identifier_value() {
        handler.handle(command: "#var one.two three four", withContext: self.context)
        XCTAssertEqual(self.context.globalVars["one.two"], "three four")
    }
}

class LocalFileSystem : FileSystem {

    var contentToLoad:String?
    var savedContent:String?
    
    func load(file: URL) -> String? {
        return contentToLoad
    }

    func save(file: URL, content: String) {
        self.savedContent = content
    }
}

class VariablesLoaderTests: XCTestCase {

    let fileSystem = LocalFileSystem()
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
