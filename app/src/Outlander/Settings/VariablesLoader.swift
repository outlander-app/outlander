//
//  VariablesLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class VariablesLoader {
    
    let filename = "variables.cfg"
    
    let files: FileSystem
    
    let regex = try? Regex("^#var \\{(.*)\\} \\{(.*)\\}$", options: [.anchorsMatchLines, .caseInsensitive])

    init(_ files:FileSystem) {
        self.files = files
    }

    func load(_ settings:ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(self.filename)

        guard let data = self.files.load(file: fileUrl) else {
            return
        }

        guard var content = String(data: data, encoding: .utf8) else {
            return
        }

        guard let matches = self.regex?.allMatches(&content) else {
            return
        }
        
        context.globalVars.removeAll()
        self.setDefaults(context)

        for match in matches {
            if match.count > 1 {
                guard let key = match.valueAt(index: 1) else {
                    continue
                }

                let value = match.valueAt(index: 2) ?? ""
                context.globalVars[key] = value
            }
        }

        context.globalVars["roundtime"] = "0"
    }

    func save(_ settings:ApplicationSettings, variables:[String:String]) {
//        let fileUrl = settings.currentProfilePath.appendingPathComponent(self.filename)
    }

    func setDefaults(_ context:GameContext) {
        context.globalVars["prompt"] = ">"
        context.globalVars["lefthand"] = "Empty"
        context.globalVars["righthand"] = "Empty"
        context.globalVars["preparedspell"] = "None"
        context.globalVars["tdp"] = "0"
    }
}
