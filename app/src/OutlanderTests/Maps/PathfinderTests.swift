//
//  PathfinderTests.swift
//  OutlanderTests
//
//  Created by Joe McBride on 11/7/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import XCTest

class PathfinderTests: XCTestCase {
    func test_pathfinding() {
        let finder = Pathfinder()
        let zone = MapZone("1", "Crossing")

        let room1 = MapNode(id: "1", name: "Room 1", descriptions: [], notes: nil, color: nil, position: MapPosition(x: 0, y: 0, z: 0), arcs: [
            MapArc(exit: "south", move: "south", destination: "2", hidden: false),
        ])
        zone.addRoom(room1)

        let room2 = MapNode(id: "2", name: "Room 2", descriptions: [], notes: nil, color: nil, position: MapPosition(x: 0, y: 10, z: 0), arcs: [
            MapArc(exit: "north", move: "north", destination: "1", hidden: false),
        ])
        zone.addRoom(room2)

        let path = finder.findPath(start: "1", target: "2", zone: zone)
        let moves = zone.getMoves(ids: path)

        XCTAssertEqual(moves, ["south"])
    }
}
