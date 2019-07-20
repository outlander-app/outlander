//
//  Regex.swift
//  Outlander
//
//  Created by Joseph McBride on 7/19/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

class Regex {
    var pattern: String
    var expression: NSRegularExpression
    
    init(_ pattern: String, options: NSRegularExpression.Options = []) throws {
        self.pattern = pattern
        self.expression = try NSRegularExpression(pattern: pattern, options: options)
    }

    public func matches(_ input: String) -> [Range<String.Index>] {
        guard let result = self.expression.firstMatch(in: input, range: NSRange(location: 0, length: input.utf8.count)) else {
            return []
        }

        var ranges: [Range<String.Index>] = []
        
        for i in 0..<result.numberOfRanges {
            let range = result.range(at: i)
            if let rng = Range(range, in: input) {
                ranges.append(rng)
            }
        }
        
        return ranges
    }
}
