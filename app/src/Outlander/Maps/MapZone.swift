//
//  MapZone.swift
//  Outlander
//
//  Created by Joe McBride on 1/29/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

extension GameContext {
    func mapForFile(file: String) -> MapZone? {
        maps.filter { _, value in value.file == file }.first?.value
    }

    func findCurrentRoom(_ zone: MapZone) -> MapNode? {
        let roomId = globalVars["roomid"] ?? ""
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

        return roomIdLookup[id.trimmingCharacters(in: .whitespacesAndNewlines)]
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

    func getMoves(ids: [String]) -> [String] {
        var moves: [String] = []
        var last: MapNode?

        for id in ids {
            if let to = last {
                if let arc = to.arc(with: id) {
                    print("move \(id) - \(arc.move)")
                    moves.append(arc.move)
                }
            }

            last = room(id: id)
        }

        return moves
    }

    func moveCostForNode(node _: MapNode, toNode _: MapNode, arc: MapArc) -> Int {
        arc.moveCost
    }

    func heuristic(node: MapNode, endNode: MapNode) -> Int {
        let index = node.position
        let toIndex = endNode.position

        // calculate distance between the two points
        let (x1, x2) = maybeSwap(a: Double(index.x), b: Double(toIndex.x))
        let (y1, y2) = maybeSwap(a: Double(index.y), b: Double(toIndex.y))

        let x = pow(x1 - x2, 2.0)
        let y = pow(y1 - y2, 2.0)
        let res = sqrt(x + y)

        return Int(res)
    }

    func maybeSwap(a: Double, b: Double) -> (Double, Double) {
        if a > b {
            return (a, b)
        }

        return (b, a)
    }
}
