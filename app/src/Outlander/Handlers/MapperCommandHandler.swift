//
//  MapperCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 1/29/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

extension TimeInterval {
    private var milliseconds: Int {
        return Int((truncatingRemainder(dividingBy: 1)) * 1000)
    }

    private var seconds: Int {
        return Int(self) % 60
    }

    private var minutes: Int {
        return (Int(self) / 60 ) % 60
    }

    private var hours: Int {
        return Int(self) / 3600
    }

    var stringTime: String {
        if hours != 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes != 0 {
            return "\(minutes)m \(seconds)s"
        } else if milliseconds != 0 {
            return "\(seconds)s \(milliseconds)ms"
        } else {
            return "\(seconds)s"
        }
    }
}

extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

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

        context.events.echoText("[Automapper]: loading all maps...")

        DispatchQueue.global(qos: .utility).async {
            let startTime = Date()

            let loader = MapLoader(self.files)
            let meta = loader.loadMapMeta(atPath: context.applicationSettings.paths.maps)
            let maps = meta.compactMap { (m) -> MapInfo? in
                switch m {
                case .Error(let e):
                    print(e)
                    context.events.echoText("Some map error")
                    return nil
                case .Success(let map):
                    return map
                }
            }

            maps.forEach {
                let start = Date()
                let result = loader.load(fileUrl: $0.file)
                switch(result) {
                case .Error(let e):
                    print(e)
                case .Success(let zone):
                    $0.zone = zone
                    print(zone.name)
                    context.maps[zone.id] = zone
//                    context.events.echoText("\(zone.name) (\((Date() - start).stringTime))")
                }
            }

            let timeElapsed = Date() - startTime
            context.events.echoText("[Automapper]: \(maps.count) maps loaded in \(timeElapsed.stringTime)")
        }
    }
}
