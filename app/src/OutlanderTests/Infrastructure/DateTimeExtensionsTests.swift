//
//  DateTimeExtensionsTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/5/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import XCTest

class DateTimeExtensionsTests: XCTestCase {
    func test_day_display() {
        let interval: TimeInterval = (3600 * 24) + 3940
        let time = interval.formatted

        XCTAssertEqual(time, "1d 1h 5m 40s")
    }

    func test_hour_display() {
        let interval: TimeInterval = 3600
        let time = interval.formatted

        XCTAssertEqual(time, "1h 0m 0s")
    }

    func test_minutes_display() {
        let interval: TimeInterval = 600
        let time = interval.formatted

        XCTAssertEqual(time, "10m 0s")
    }

    func test_seconds_display() {
        let interval: TimeInterval = 100
        let time = interval.formatted

        XCTAssertEqual(time, "1m 40s")
    }

    func test_ms_display() {
        let interval: TimeInterval = 50.5
        let time = interval.formatted

        XCTAssertEqual(time, "50s 500ms")
    }
}
