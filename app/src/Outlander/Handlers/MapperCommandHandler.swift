//
//  MapperCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 1/29/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class MapperComandHandler: ICommandHandler {
    var command = "#mapper"

    let files: FileSystem
    let log = LogManager.getLog(String(describing: MapperComandHandler.self))

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ command: String, with context: GameContext) {
        let command = command[7...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        guard command.count > 0 else {
            return
        }

        switch command {
        case "reload":
            reload(with: context)
        case "reset":
            context.resetMap()
        default:
            context.events.echoText("[AutoMapper]: unknown command '\(command)'", preset: "automapper")
        }
    }

    func reload(with context: GameContext) {
        context.events.echoText("[AutoMapper]: loading all maps...", preset: "automapper")

        DispatchQueue.global(qos: .utility).async {
            let startTime = Date()

            let loader = MapLoader(self.files)
            let meta = loader.loadMapMeta(atPath: context.applicationSettings.paths.maps)
            let maps = meta.compactMap { m -> MapInfo? in
                switch m {
                case let .Error(e):
                    context.events.echoText("[AutoMapper]: An error occured loading metadata:\n    \(e.description)", preset: "scripterror", mono: true)
                    return nil
                case let .Success(map):
                    return map
                }
            }

            maps.forEach {
                // a note
                let result = loader.load(fileUrl: $0.file)
                switch result {
                case let .Error(e):
                    context.events.echoText("[AutoMapper]: An error occured loading map \($0.file.absoluteString):\n    \(e.description)", preset: "scripterror", mono: true)
                case let .Success(zone):
                    $0.zone = zone
                    context.maps[zone.id] = zone
                }
            }

            let timeElapsed = Date() - startTime
            context.events.echoText("[AutoMapper]: \(maps.count) maps loaded in \(timeElapsed.formatted)", preset: "automapper")
            context.resetMap()
        }
    }
}

extension GameContext {
    func trimmedRoomTitle() -> String {
        let name = globalVars["roomtitle"] ?? ""
        return name.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    }

    func availableExits() -> [String] {
        let dirs = [
            "down",
            "east",
            "north",
            "northeast",
            "northwest",
            "out",
            "south",
            "southeast",
            "southwest",
            "up",
            "west",
        ]

        var avail: [String] = []

        for dir in dirs {
            let value = globalVars[dir] ?? ""
            if value == "1" {
                avail.append(dir)
            }
        }

        return avail
    }
}
