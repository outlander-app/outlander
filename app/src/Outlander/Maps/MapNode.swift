//
//  MapNode.swift
//  Outlander
//
//  Created by Joseph McBride on 6/12/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct MapArc {
    var exit: String
    var move: String
    var destination: String
    var hidden: Bool

    var destinationValue: Int {
        Int(destination) ?? 0
    }

    var hasDestination: Bool {
        destination.count > 0
    }
}

struct MapPosition {
    var x: Int
    var y: Int
    var z: Int
}

final class MapNode {
    var id: String
    var name: String
    var descriptions: [String]
    var notes: String?
    var color: String?
    var arcs: [MapArc]
    var position: MapPosition

    private let cardinalDirs = [
        "north",
        "south",
        "east",
        "west",
        "northeast",
        "northwest",
        "southeast",
        "southwest",
        "out",
        "up",
        "down",
    ]

    init(id: String, name: String, descriptions: [String], notes: String?, color: String?, position: MapPosition, arcs: [MapArc]) {
        self.id = id
        self.name = name
        self.descriptions = descriptions
        self.notes = notes
        self.color = color
        self.position = position
        self.arcs = arcs
    }

    var transferMap: String? {
        if isTransfer() {
            guard var notes = notes else {
                return nil
            }
            guard let result = RegexFactory.get("(.+\\.xml)")?.firstMatch(&notes) else {
                return nil
            }
            guard result.count > 0 else {
                return nil
            }
            return result.valueAt(index: 1)
        }

        return nil
    }

    var filteredArcs: [MapArc] {
        arcs
            .filter { $0.hasDestination }
            .sorted { $0.destinationValue < $1.destinationValue }
    }

    func isTransfer() -> Bool {
        notes?.contains(".xml") == true
    }

    func arc(with id: String) -> MapArc? {
        arcs.filter { $0.destination == id }.first
    }

    func nonCardinalExists() -> [MapArc] {
        arcs.filter { !self.cardinalDirs.contains($0.exit) }
    }

    func cardinalExits() -> [String] {
        arcs.filter { self.cardinalDirs.contains($0.exit) }.map { $0.exit }.sorted()
    }

    func matchesExits(_ exits: [String]) -> Bool {
        cardinalExits().elementsEqual(exits, by: {
            $0 == $1
        })
    }

    func matches(name: String, description: String, exits: [String], ignoreTransfers: Bool) -> Bool {
        if ignoreTransfers, isTransfer() {
            return false
        }

        if exits.count > 0 {
            return matchesExits(exits)
                && self.name == name
                && hasMatchingDescription(description)
        }

        return self.name == name && hasMatchingDescription(description)
    }

    func hasMatchingDescription(_ description: String) -> Bool {
        let mod = description.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ";", with: "")

        for desc in descriptions {
            if desc.hasPrefix(mod) {
                return true
            }
        }
        return false
    }
}
