//
//  RegexTester.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/16/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import XCTest

class RegexTester: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func test_replace() {
        let text = "flickering mana to the west\n"
        let regex = try! Regex("flickering mana to the", options: [])

        let result = regex.replace(text, with: "flickering mana (8/21) to the")

        XCTAssertEqual(result, "flickering mana (8/21) to the west\n")
    }
    

    func test_replace2() {
        let text = "flickering mana to the west\n"
        
        let result = text.replacingOccurrences(of: "flickering mana to the", with: "flickering mana (8/21) to the")

        XCTAssertEqual(result, "flickering mana (8/21) to the west\n")
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
