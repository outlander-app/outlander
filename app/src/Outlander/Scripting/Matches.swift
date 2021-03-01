//
//  Matches.swift
//  Outlander
//
//  Created by Joe McBride on 2/28/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

protocol IMatch {
    var value: String {get}
    var label: String {get}
    var lineNumber: Int {get}
    var groups: [String] {get}

    func isMatch(_ text:String) -> Bool
}

class Matchwait {
    var id:String

    init() {
        self.id = UUID().uuidString
    }
}

class MatchMessage : IMatch {
    var value: String
    var label: String
    var lineNumber: Int
    var groups: [String]

    init(_ label: String, _ value: String, _ lineNumber: Int) {
        self.label = label
        self.value = value
        self.lineNumber = lineNumber
        self.groups = []
    }

    func isMatch(_ text: String) -> Bool {
        // TODO: resolve variables in value
        return text.range(of: value) != nil
    }
}

class MatchreMessage : IMatch {
    var value: String
    var label: String
    var lineNumber: Int
    var groups: [String]

    init(_ label: String, _ value: String, _ lineNumber: Int) {
        self.label = label
        self.value = value
        self.lineNumber = lineNumber
        self.groups = []
    }

    func isMatch(_ text: String) -> Bool {
        // TODO: resolve variables in value
        let val = value
        var txt = text
        let regex = RegexFactory.get(val)
        guard let match = regex?.firstMatch(&txt) else {
            return false
        }

        groups = match.values()
        return groups.count > 0
    }
}
