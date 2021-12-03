//
//  IconLoader.swift
//  Outlander
//
//  Created by Joe McBride on 12/2/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

class IconLoader {
    private var files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ paths: ApplicationPaths) -> [String: URL] {
        let imageFiles = [
            "dead": paths.icons.appendingPathComponent("dead.png"),
            "standing": paths.icons.appendingPathComponent("standing.png"),
            "kneeling": paths.icons.appendingPathComponent("kneeling.png"),
            "sitting": paths.icons.appendingPathComponent("sitting.png"),
            "prone": paths.icons.appendingPathComponent("prone.png"),
            "stunned": paths.icons.appendingPathComponent("stunned.png"),
            "bleeding": paths.icons.appendingPathComponent("bleeding.png"),
            "invisible": paths.icons.appendingPathComponent("invisible.png"),
            "hidden": paths.icons.appendingPathComponent("hidden.png"),
            "joined": paths.icons.appendingPathComponent("joined.png"),
            "webbed": paths.icons.appendingPathComponent("webbed.png"),
            "poisoned": paths.icons.appendingPathComponent("poisoned.png"),
            "directions": paths.icons.appendingPathComponent("directions.png"),
            "north": paths.icons.appendingPathComponent("north.png"),
            "south": paths.icons.appendingPathComponent("south.png"),
            "east": paths.icons.appendingPathComponent("east.png"),
            "west": paths.icons.appendingPathComponent("west.png"),
            "northeast": paths.icons.appendingPathComponent("northeast.png"),
            "northwest": paths.icons.appendingPathComponent("northwest.png"),
            "southeast": paths.icons.appendingPathComponent("southeast.png"),
            "southwest": paths.icons.appendingPathComponent("southwest.png"),
            "out": paths.icons.appendingPathComponent("out.png"),
            "up": paths.icons.appendingPathComponent("up.png"),
            "down": paths.icons.appendingPathComponent("down.png"),
        ]

        files.access {
            for (imageName, url) in imageFiles {
                if !self.files.fileExists(url) {
                    print("\(url) does not exist, creating")
                    NSImage(named: imageName)?.pngWrite(to: url)
                }
            }
        }

        return imageFiles
    }
}
