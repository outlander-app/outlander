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
        events2 = events
        applicationSettings = ApplicationSettings()
        globalVars = GlobalVariables(events: events, settings: applicationSettings)
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
        let obscured = globalVars["roomobscured"]

        var tags: [TextTag] = []
        var room = ""

        if !name.isEmptyOrNil {
            let tag = TextTag.tagFor(name!, preset: "roomname")
            tags.append(tag)
            room += "\n"
        }

        if !desc.isEmptyOrNil {
            let tag = TextTag.tagFor("\(room)\(desc!)\n", preset: "roomdesc")
            tags.append(tag)
            room = ""
        }

        if !objects.isEmptyOrNil {
            room += "\(objects!)\n"
        }

        if !players.isEmptyOrNil {
            room += "\(players!)\n"
        }

        if !exits.isEmptyOrNil {
            room += "\(exits!)\n"
        }

        tags.append(TextTag.tagFor(room))

        if let zone = mapZone, let currentRoom = findCurrentRoom(zone) {
            if obscured?.toBool() == true && currentRoom.cardinalExits().count > 0 {
                let cardinalExits = currentRoom.cardinalExits().joined(separator: ", ")
                tags.append(TextTag.tagFor("Mapped directions:: \(cardinalExits)", preset: "automapper"))
            }
            
            let mappedExits = currentRoom.nonCardinalExists().map(\.move).joined(separator: ", ")
            if mappedExits.count > 0 {
                tags.append(TextTag.tagFor("Mapped exits: \(mappedExits)", preset: "automapper"))
            }
        }

        return tags
    }
}
