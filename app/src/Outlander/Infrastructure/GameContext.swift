//
//  GameContext.swift
//  Outlander
//
//  Created by Joseph McBride on 5/16/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class GameContext {
    var events2: Events2

    var applicationSettings: ApplicationSettings
    var layout: WindowLayout?
    var globalVars: Variables
    var presets: [String: ColorPreset] = [:]
    var classes = ClassSettings()
    var gags: [Gag] = []
    var macros: [String: Macro] = [:]
    var aliases: [Alias] = []
    var highlights = Highlights()
    var substitutes = Substitutes()
    var triggers: [Trigger] = []
    var maps: [String: MapZone] = [:]
    var mapZone: MapZone? {
        didSet {
            globalVars["zoneid"] = mapZone?.id ?? ""
            globalVars["zonename"] = mapZone?.name ?? ""
        }
    }

    init(_ events: Events2 = SwenEvents()) {
        self.events2 = events
        self.applicationSettings = ApplicationSettings()
        self.globalVars = GlobalVariables(events: events, settings: self.applicationSettings)
    }

    func updateClassFilters() {
        highlights.updateActiveCache(with: classes.disabled())
        substitutes.updateActiveCache(with: classes.disabled())
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
