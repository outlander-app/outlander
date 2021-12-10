//
//  PrintBox.swift
//  Outlander
//
//  Created by Joe McBride on 12/10/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

struct PrintBox {
    static func print(_ input: String, topElement: Character = "*", sideElement: Character = "*", cornerElement: Character = "*", sideBoxCount: Int = 2, innerPadding: Int = 2) -> [String] {
        let lines = input.split(separator: "|")
        let longest = lines.max(by: { $1.count > $0.count })!.count

        let sides = String(repeatElement(sideElement, count: sideBoxCount))
        let padding = String(repeatElement(" ", count: innerPadding))

        var result: [String] = []

        let start = String(cornerElement) + String(repeatElement(topElement, count: longest - 2 + (innerPadding * 2) + sides.count * 2)) + String(cornerElement)
        result.append(start)
        for line in lines {
            result.append("\(sides)\(padding)\(String(line).rightPadding(toLength: longest))\(padding)\(sides)")
        }
        result.append(start)

        return result
    }
}
