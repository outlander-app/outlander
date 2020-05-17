//
//  GameContext.swift
//  Outlander
//
//  Created by Joseph McBride on 5/16/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class GameContext {
    var events: Events = SwiftEventBusEvents()
    
    var applicationSettings: ApplicationSettings = ApplicationSettings()
    var layout: WindowLayout?
    var globalVars: [String:String] = [:]
    var presets: [String:ColorPreset] = [:]
    var classes: ClassSettings = ClassSettings()
    var gags: [Gag] = []
    var aliases: [Alias] = []
    var highlights: [Highlight] = []
    var substitutes: [Substitute] = []
    var triggers: [Trigger] = []
}

extension GameContext {
    func buildRoomTags() -> [TextTag] {
        let vars = self.globalVars
        let name = vars["roomtitle"]
        let desc = vars["roomdesc"]
        let objects = vars["roomobjs"]
        let players = vars["roomplayers"]
        let exits = vars["roomexits"]

        var tags:[TextTag] = []
        var room = ""

        if name != nil && name?.count ?? 0 > 0 {
            let tag = TextTag.tagFor(name!, preset: "roomname")
            tags.append(tag)
            room += "\n"
        }
        
        if desc != nil && desc?.count ?? 0 > 0 {
            let tag = TextTag.tagFor("\(room)\(desc!)\n", preset: "roomdesc")
            tags.append(tag)
            room = ""
        }
        
        if objects != nil && objects?.count ?? 0 > 0 {
            room += "\(objects!)\n"
        }
        
        if players != nil && players?.count ?? 0 > 0 {
            room += "\(players!)\n"
        }
        
        if exits != nil && exits?.count ?? 0 > 0 {
            room += "\(exits!)\n"
        }

        tags.append(TextTag.tagFor(room))

        return tags
    }
}
