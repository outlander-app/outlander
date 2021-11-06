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
    var mapZone: MapZone?

    init() {
        globalVars = Variables(events: events)
    }
}

class Variables {
    private let lockQueue = DispatchQueue(label: "com.outlanderapp.variables.\(UUID().uuidString)")
    private var vars: [String: String] = [:]
    private var events: Events

    init(events: Events) {
        self.events = events
    }

    subscript(key: String) -> String? {
        get {
            lockQueue.sync {
                vars[key]
            }
        }
        set(newValue) {
            lockQueue.sync(flags: .barrier) {
                let res = newValue ?? ""
                vars[key] = res
                DispatchQueue.main.async {
                    self.events.variableChanged(key, value: res)
                }
            }
        }
    }

    var count: Int {
        lockQueue.sync {
            vars.count
        }
    }

    func removeAll() {
        lockQueue.sync(flags: .barrier) {
            vars.removeAll()
        }
    }

    func sorted() -> [(String, String)] {
        lockQueue.sync(flags: .barrier) {
            vars.sorted(by: { $0.key < $1.key })
        }
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

        return tags
    }
}
