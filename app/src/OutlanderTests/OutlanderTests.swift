//
//  OutlanderTests.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 7/18/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import XCTest
@testable import Outlander

class OutlanderTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testExample() {
        let testdata = "L    OK    UPPORT=5535    GAME=WIZ    GAMECODE=DR    FULLGAMENAME=Wizard Front End    GAMEFILE=WIZARD.EXE    GAMEHOST=dr.simutronics.net    GAMEPORT=4901    KEY=a6e753347ae0e0131d2e373bc70a3f3b"
        let result = try? Regex("KEY=(\\w+)").matches(testdata)
        let data = testdata[result![1]]
        XCTAssertEqual(data, "a6e753347ae0e0131d2e373bc70a3f3b")
    }
    
    func testAnotherExample() {
        let testdata = "C\t1\t1\t0\t0\tW_ACCT_000\tCharName"
        let result = try? Regex("(\\S_\\S[\\S0-9]+)\tCharName").matches(testdata)
        let data = testdata[result![1]]
        XCTAssertEqual(data, "W_ACCT_000")
    }
}
