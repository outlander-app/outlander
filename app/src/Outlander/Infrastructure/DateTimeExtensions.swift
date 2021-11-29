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

    var formatted: String {
        let result = format(using: [.day, .hour, .minute, .second]) ?? ""

        if self < 60 {
            return "\(result) \(milliseconds)ms"
        }

        return result
    }

    func format(using units: NSCalendar.Unit) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropLeading

        return formatter.string(from: self)
    }
}

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}
