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

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ command: String, with context: GameContext) {
        let commands = command[7...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).components(separatedBy: " ")

        print("mapper commands \(commands)")

//        guard commands.count > 0 else {
//            return
//        }

        context.events.echoText("[Automapper]: loading all maps...", preset: "automapper")

        DispatchQueue.global(qos: .utility).async {
            let startTime = Date()

            let loader = MapLoader(self.files)
            let meta = loader.loadMapMeta(atPath: context.applicationSettings.paths.maps)
            let maps = meta.compactMap { (m) -> MapInfo? in
                switch m {
                case let .Error(e):
                    context.events.echoText("An error occured loading metadata:\n    \(e.description)", preset: "scripterror", mono: true)
                    return nil
                case let .Success(map):
                    return map
                }
            }

            maps.forEach {
                let result = loader.load(fileUrl: $0.file)
                switch result {
                case let .Error(e):
                    context.events.echoText("An error occured loading map \($0.file.absoluteString):\n    \(e.description)", preset: "scripterror", mono: true)
                case let .Success(zone):
                    $0.zone = zone
                    context.maps[zone.id] = zone
                }
            }

            let timeElapsed = Date() - startTime
            context.events.echoText("[Automapper]: \(maps.count) maps loaded in \(timeElapsed.stringTime)", preset: "automapper")
        }
    }
}
