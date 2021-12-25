//
//  DateFormats.swift
//  Outlander
//
//  Created by Joe McBride on 12/24/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

struct DateFormats {
    internal static var sharedFormatter = DateFormatter()

    internal static let builtInAutoFormat: [String] =  [
        "yyyy-MM-dd HH:mm",
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd hh:mm:ss a",
        "yyyy/MM/dd HH:mm",
        "yyyy/MM/dd HH:mm:ss",
        "yyyy/MM/dd HH:mm:ss a",
        "MM-dd-yyyy HH:mm",
        "MM-dd-yyyy HH:mm:ss",
        "MM-dd-yyyy HH:mm:ss a",
        "MM/dd/yyyy HH:mm",
        "MM/dd/yyyy HH:mm:ss",
        "MM/dd/yyyy HH:mm:ss a",
    ]

    public static func resetAutoFormats() {
        autoFormats = DateFormats.builtInAutoFormat
    }

    public static var autoFormats: [String] = DateFormats.builtInAutoFormat

    public static func parse(_ string: String, format: String? = nil) -> Date? {
        let formats = (format != nil ? [format!] : DateFormats.autoFormats)
        return DateFormats.parse(string, formats: formats)
    }

    public static func parse(_ string: String, formats: [String]) -> Date? {
        let formatter = sharedFormatter

        var parsedDate: Date?
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                parsedDate = date
                break
            }
        }
        return parsedDate
    }
}
