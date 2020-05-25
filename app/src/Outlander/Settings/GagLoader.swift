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
        
        context.add(gag: &content)
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

extension GameContext {
    
    static let regex = try? Regex("^#gag \\{(.*?)\\}(?:\\s\\{(.*?)\\})?$", options: [.anchorsMatchLines, .caseInsensitive])
    
    func add(gag: Gag) {
        self.gags.append(gag)
    }
    
    func add(gag: inout String) {
        guard let matches = GameContext.regex?.allMatches(&gag) else {
            return
        }
        
        for match in matches {
            if match.count == 3 {
                guard let pattern = match.valueAt(index: 1) else {
                    continue
                }

                let className = match.valueAt(index: 2) ?? ""
                self.add(gag: Gag(pattern: pattern, className: className.lowercased()))
            }
        }
    }
}
