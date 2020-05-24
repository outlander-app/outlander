//
//  GagLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct Gag: CustomStringConvertible {
    var pattern: String
    var className: String
    
    var description: String {
        return "#gag {\(self.pattern)} {\(self.className)}"
    }
}

class GagLoader {
    let filename = "gags.cfg"

    let files: FileSystem

    let regex = try? Regex("^#gag \\{(.*?)\\}(?:\\s\\{(.*?)\\})?$", options: [.anchorsMatchLines, .caseInsensitive])
    
    init(_ files:FileSystem) {
        self.files = files
    }

    func load(_ settings:ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(self.filename)
        
        context.gags.removeAll()

        guard let data = self.files.load(fileUrl) else {
            return
        }
        
        guard var content = String(data: data, encoding: .utf8) else {
            return
        }
        
        self.addFromStr(settings, context: context, gagStr: &content)
    }
    
    func addFromStr(_ settings:ApplicationSettings, context: GameContext, gagStr: inout String) {
        guard let matches = self.regex?.allMatches(&gagStr) else {
            return
        }
        
        for match in matches {
            if match.count == 3 {
                guard let pattern = match.valueAt(index: 1) else {
                    continue
                }

                let className = match.valueAt(index: 2) ?? ""
                self.add(settings, context: context, gag: Gag(pattern: pattern, className: className.lowercased()))
            }
        }
    }
    
    func add(_ settings:ApplicationSettings, context: GameContext, gag: Gag) {
        context.gags.append(gag)
    }
    
    func save(_ settings: ApplicationSettings, gags: [Gag]) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(self.filename)

        var content = ""
        for gag in gags {
            content += "#gag {\(gag.pattern)}"

            if gag.className.count > 0 {
                content += " {\(gag.className.lowercased())}"
            }

            content += "\n"
        }
        
        self.files.write(content, to: fileUrl)
    }
}
