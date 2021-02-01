//
//  MapZone.swift
//  Outlander
//
//  Created by Joe McBride on 1/29/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

extension GameContext {
    func findCurrentRoom(_ zone: MapZone) -> MapNode? {
        let roomId = self.globalVars["roomid"] ?? ""
        return zone.room(id: roomId)
    }
}

struct MapLabel {
    var text: String
    var position: MapPosition
}

final class MapZone {
    var id: String
    var name: String
    var file: String
    var rooms: [MapNode]
    var labels: [MapLabel]
    var roomIdLookup: [String: MapNode]

    init(_ id: String, _ name: String) {
        self.id = id
        self.name = name
        file = ""
        rooms = []
        labels = []
        roomIdLookup = [:]
    }

    func addRoom(_ room: MapNode) {
        rooms.append(room)
        roomIdLookup[room.id] = room
    }

    func mapSize(_: Int, padding: Double) -> NSRect {
        var maxX: Double = 0
        var minX: Double = 0
        var maxY: Double = 0
        var minY: Double = 0

        for room in rooms {
            if Double(room.position.x) > maxX {
                maxX = Double(room.position.x)
            }

            if Double(room.position.x) < minX {
                minX = Double(room.position.x)
            }

            if Double(room.position.y) > maxY {
                maxY = Double(room.position.y)
            }

            if Double(room.position.y) < minY {
                minY = Double(room.position.y)
            }
        }

        let width: Double = abs(maxX) + abs(minX) + padding
        let height: Double = abs(maxY) + abs(minY) + padding

//        print("maxX: \(maxX) minX: \(minX) maxY: \(maxY) minY: \(minY) || (\(width),\(height))")
        // set origin x,y to the point on screen where were the most points can fit on screen
        // between maxX and maxY
        return NSRect(x: width - maxX - (padding / 2.0), y: height - maxY - (padding / 2.0), width: width * 1.0, height: height * 1.0)
    }

    func room(id: String) -> MapNode? {
        if id.count == 0 {
            return nil
        }

        return roomIdLookup[id]
    }

    func rooms(note: String) -> [MapNode] {
        rooms.filter {
            if let notes = $0.notes {
                let split = notes.lowercased().components(separatedBy: "|")
                let filter = split
                    .filter { $0.hasPrefix(note.lowercased()) }

                return filter.count > 0
            }

            return false
        }
    }
}
