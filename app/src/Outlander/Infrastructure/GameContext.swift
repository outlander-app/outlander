//
//  GameContext.swift
//  Outlander
//
//  Created by Joseph McBride on 5/16/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class LocalHost: IHost {
    var context: GameContext

    init(context: GameContext) {
        self.context = context
    }

    func send(text: String) {
        context.events.sendCommand(Command2(command: text, isSystemCommand: true))
    }

    func get(variable: String) -> String {
        context.globalVars[variable] ?? ""
    }

    func set(variable: String, value: String) {
        context.globalVars[variable] = value
    }
}

class GameContext {
    var events: Events = SwiftEventBusEvents()

    var applicationSettings = ApplicationSettings()
    var layout: WindowLayout?
    var globalVars: Variables
    var presets: [String: ColorPreset] = [:]
    var classes = ClassSettings()
    var gags: [Gag] = []
    var macros: [String: Macro] = [:]
    var aliases: [Alias] = []
    var highlights: [Highlight] = []
    var substitutes: [Substitute] = []
    var triggers: [Trigger] = []
    var maps: [String: MapZone] = [:]
    var mapZone: MapZone? {
        didSet {
            globalVars["zoneid"] = mapZone?.id ?? ""
        }
    }

    init() {
        globalVars = Variables(events: events, settings: applicationSettings)
    }
}

extension GameContext {
    func buildRoomTags() -> [TextTag] {
        let name = globalVars["roomtitle"]
        let desc = globalVars["roomdesc"]
        let objects = globalVars["roomobjs"]
        let players = globalVars["roomplayers"]
        let exits = globalVars["roomexits"]

        var tags: [TextTag] = []
        var room = ""

        if name != nil, name?.count ?? 0 > 0 {
            let tag = TextTag.tagFor(name!, preset: "roomname")
            tags.append(tag)
            room += "\n"
        }

        if desc != nil, desc?.count ?? 0 > 0 {
            let tag = TextTag.tagFor("\(room)\(desc!)\n", preset: "roomdesc")
            tags.append(tag)
            room = ""
        }

        if objects != nil, objects?.count ?? 0 > 0 {
            room += "\(objects!)\n"
        }

        if players != nil, players?.count ?? 0 > 0 {
            room += "\(players!)\n"
        }

        if exits != nil, exits?.count ?? 0 > 0 {
            room += "\(exits!)\n"
        }

        tags.append(TextTag.tagFor(room))

        if let zone = mapZone, let currentRoom = findCurrentRoom(zone) {
            let mappedExits = currentRoom.nonCardinalExists().map { $0.move }.joined(separator: ", ")
            if mappedExits.count > 0 {
                tags.append(TextTag.tagFor("Mapped exits: \(mappedExits)", preset: "automapper"))
            }
        }

        return tags
    }
}
