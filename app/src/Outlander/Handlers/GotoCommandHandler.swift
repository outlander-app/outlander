//
//  GotoCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 11/7/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class GotoComandHandler: ICommandHandler {
    var command = "#goto"

    let log = LogManager.getLog(String(describing: GotoComandHandler.self))

    func handle(_ command: String, with context: GameContext) {
        let area = command[5...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)

        log.info("goto \(area)")
        let zone = context.maps["1"]!
        let (toRoom, matches) = room(for: zone, area: area)

        for match in matches {
            context.events.echoText("\(match.id) \(match.name)")
        }
//        context.events.echoText("to: \(toRoom?.id) \(toRoom?.name)")

        if let toRoom = toRoom {
            let start = Date()
            let finder = Pathfinder()
            let path = finder.findPath(start: "585", target: toRoom.id, zone: zone)
            let moves = zone.getMoves(ids: path)
            let diff = Date() - start
            context.events.echoText(path.joined(separator: ", "))
            context.events.echoText("found path in: \(diff.formatted)")
            context.events.echoText(moves.joined(separator: ", "))
        }
    }

    func room(for zone: MapZone?, area: String) -> (MapNode?, [MapNode]) {
        guard let zone = zone else {
            return (nil, [])
        }

        let matches = zone.rooms(note: area)
        var toRoom = matches.last

        if toRoom == nil {
            toRoom = zone.room(id: area)
        }

        return (toRoom, matches)
    }
}
