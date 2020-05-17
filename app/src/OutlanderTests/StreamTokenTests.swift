//
//  StreamTokenTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/16/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class StreamTokenTests: XCTestCase {
    var reader:GameStreamTokenizer = GameStreamTokenizer()

    override func setUp() {
    }

    override func tearDown() {
    }

    func test_monsters() {
        let line = "<component id='room objs'>You also see <pushBold/>a juvenile wyvern<popBold/>, <pushBold/>a juvenile wyvern<popBold/>, a rocky path, <pushBold/>a juvenile wyvern<popBold/> and some junk.</component>\n"

        let token = reader.read(line).first!

        let monsters = token.monsters()
        
        XCTAssertEqual(monsters.count, 3)
    }
}
