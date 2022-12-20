//
//  GotoCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 11/7/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

struct AutomapperPathEvent: Event {
    var path: [String]
}

class GotoComandHandler: ICommandHandler {
    var command = "#goto"

    let log = LogManager.getLog(String(describing: GotoComandHandler.self))

    private var started = Date()

    func handle(_ input: String, with context: GameContext) {
        let area = input[command.count...].trimmingCharacters(in: .whitespacesAndNewlines).lowercased().components(separatedBy: "from")

        started = Date()

        DispatchQueue.global(qos: .userInteractive).async {
            if area.count > 1 {
                self.gotoArea(area: area[0].trimmingCharacters(in: .whitespaces), from: area[1].trimmingCharacters(in: .whitespaces), context: context)
            } else if area.count > 0 {
                self.gotoArea(area: area[0].trimmingCharacters(in: .whitespaces), context: context)
            }
        }
    }

    func gotoArea(area: String, context: GameContext) {
        var to: MapNode?
        var from: MapNode?
        var matches: [MapNode] = []

        if let zone = context.mapZone {
            let roomId = context.globalVars["roomid"] ?? ""
            from = zone.room(id: roomId)

            let (toRoom, m) = room(for: zone, area: area)
            to = toRoom
            matches = m
        }

        goto(to: to, from: from, matches: matches, area: area, context: context)
    }

    func gotoArea(area: String, from: String, context: GameContext) {
        let (fromRoom, _) = room(for: context.mapZone, area: from)
        let (toRoom, matches) = room(for: context.mapZone, area: area)

        goto(to: toRoom, from: fromRoom, matches: matches, area: area, context: context)
    }

    func processMoves(moves: [String], context: GameContext) {
        let args = moves.map {
            $0.range(of: " ") != nil
                ? "\"\($0)\""
                : $0
        }.joined(separator: " ")

        // what if I saved \(args) to $mapperpath global var? ~DAH
        let mapperpath = moves.map {
            $0.range(of: " ") != nil
                ? "\"\($0)\""
                : $0
        }.joined(separator: "|")
        context.globalVars["mapperpath"] = mapperpath

        context.events2.sendCommand(Command2(command: ".automapper \(args)", isSystemCommand: true))
    }

    func goto(to: MapNode?, from: MapNode?, matches: [MapNode], area: String, context: GameContext) {
        guard let zone = context.mapZone else {
            let msg = "no map data loaded"
            context.events2.echoError(msg)
            context.events2.sendCommand(Command2(command: "#parse \(msg)", isSystemCommand: true))
            context.events2.sendCommand(Command2(command: "#parse AUTOMAPPER NO MAP DATA", isSystemCommand: true))
            return
        }

        guard let to = to, let from = from else {
            let msg = "no path found for \"\(area)\""
            context.events2.echoError(msg)
            context.events2.sendCommand(Command2(command: "#parse \(msg)", isSystemCommand: true))
            context.events2.sendCommand(Command2(command: "#parse AUTOMAPPER NO PATH FOUND", isSystemCommand: true))
            return
        }

        if to.id == from.id {
            let msg = "You are already here!"
            context.events2.echoText("[AutoMapper]: \(msg)", preset: "automapper")
            context.events2.sendCommand(Command2(command: "#parse \(msg)", isSystemCommand: true))
            context.events2.sendCommand(Command2(command: "#parse AUTOMAPPER ALREADY HERE", isSystemCommand: true))
            return
        }

        for match in matches {
            context.events2.echoText("[AutoMapper]: \(match)", preset: "automapper")
        }

        let finder = Pathfinder()
        let path = finder.findPath(start: from.id, target: to.id, zone: zone)
        let moves = zone.getMoves(ids: path)
        let diff = Date() - started

        context.events2.post(AutomapperPathEvent(path: path))

        if context.globalVars["debugautomapper"]?.toBool() == true {
            context.events2.echoText("[AutoMapper] (debug): " + moves.joined(separator: ", "), preset: "automapper")
            context.events2.echoText("[AutoMapper] (debug): found path in: \(diff.formatted)", preset: "automapper")
        }
        processMoves(moves: moves, context: context)
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
