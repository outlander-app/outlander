//
//  DateTimeExtensions.swift
//  Outlander
//
//  Created by Joe McBride on 1/29/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

extension TimeInterval {
    private var milliseconds: Int {
        Int(truncatingRemainder(dividingBy: 1) * 1000)
    }

    private var seconds: Int {
        Int(self) % 60
    }

    private var minutes: Int {
        (Int(self) / 60) % 60
    }

    private var hours: Int {
        Int(self) / 3600
    }

    var stringTime: String {
        if hours != 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes != 0 {
            return "\(minutes)m \(seconds)s"
        } else if milliseconds != 0 {
            return "\(seconds)s \(milliseconds)ms"
        } else {
            return "\(seconds)s"
        }
    }
}

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}
