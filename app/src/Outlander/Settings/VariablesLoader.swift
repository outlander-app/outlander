//
//  VariablesLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

protocol FileSystem {
    func load(file:URL) -> String?
    func save(file:URL, content:String)
}

class VariablesLoader {
    
    let files:FileSystem

    init(_ files:FileSystem) {
        self.files = files
    }

    func load(_ settings:ApplicationSettings, context: GameContext) {
        let fileUrl = settings.paths.profiles.appendingPathComponent("variable.cfg")

        let content = self.files.load(file: fileUrl) ?? ""

        guard let matches = try? Regex("^#var \\{(.*)\\} \\{(.*)\\}$", options: [.anchorsMatchLines]).allMatches(content) else {
            return
        }

        for match in matches {
            if match.count > 1 {
                guard let key = match.valueAt(index: 1) else {
                    continue
                }

                let value = match.valueAt(index: 2) ?? ""
                context.globalVars[key] = value
            }
        }
    }

    func save(_ settings:ApplicationSettings, variables:[String:String]) {
    }
}
