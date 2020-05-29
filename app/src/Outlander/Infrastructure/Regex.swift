//
//  Regex.swift
//  Outlander
//
//  Created by Joseph McBride on 7/19/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

extension Regex: Hashable {
    static func == (lhs: Regex, rhs: Regex) -> Bool {
        return lhs.pattern == rhs.pattern
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(pattern)
    }
}

class Regex {
    var pattern: String
    var expression: NSRegularExpression

    init(_ pattern: String, options: NSRegularExpression.Options = []) throws {
        self.pattern = pattern
        expression = try NSRegularExpression(pattern: pattern, options: options)
    }

    public func replace(_ input: String, with template: String) -> String {
        let range = NSRange(input.startIndex..., in: input)
        return expression.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: template)
    }

    public func matches(_ input: String) -> [Range<String.Index>] {
        guard let result = expression.firstMatch(in: input, range: NSRange(location: 0, length: input.utf8.count)) else {
            return []
        }

        var ranges: [Range<String.Index>] = []

        for i in 0 ..< result.numberOfRanges {
            let range = result.range(at: i)
            if let rng = Range(range, in: input) {
                ranges.append(rng)
            }
        }

        return ranges
    }

    public func hasMatches(_ input: String) -> Bool {
        var input2 = input
        return firstMatch(&input2) != nil
    }

    public func firstMatch(_ input: inout String) -> MatchResult? {
        guard let result = expression.firstMatch(in: input, range: NSRange(location: 0, length: input.utf8.count)) else {
            return nil
        }

        return MatchResult(&input, result: result)
    }

    public func allMatches(_ input: inout String) -> [MatchResult] {
        let results = expression.matches(in: input, range: NSRange(location: 0, length: input.utf8.count))
        return results.map { res in
            MatchResult(&input, result: res)
        }
    }
}

class MatchResult {
    private let input: String
    private let result: NSTextCheckingResult

    init(_ input: inout String, result: NSTextCheckingResult) {
        self.input = input
        self.result = result
    }

    var count: Int {
        return result.numberOfRanges
    }

    func rangeOf(index: Int) -> NSRange? {
        guard index < result.numberOfRanges else {
            return nil
        }

        return result.range(at: index)
    }

    func valueAt(index: Int) -> String? {
        guard index < result.numberOfRanges else {
            return nil
        }

        let rangeIndex = result.range(at: index)
        if let range = Range(rangeIndex, in: input) {
            return String(input[range])
        }

        return nil
    }
}
