//
//  AliasLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct Alias {
    var pattern: String
    var replace: String
    var className: String?
    
    var description: String {
        return "#alias {\(self.pattern)} {\(self.replace)} {\(self.className ?? "")}"
    }
}

class AliasLoader {
    let filename = "aliases.cfg"

    let files: FileSystem
    
    init(_ files:FileSystem) {
        self.files = files
    }

    func load(_ settings:ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(self.filename)

        context.aliases.removeAll()

        guard let data = self.files.load(fileUrl) else {
            return
        }
        
        guard var content = String(data: data, encoding: .utf8) else {
            return
        }

        context.addAlias(alias: &content)
    }
    
    func save(_ settings: ApplicationSettings, aliases: [Alias]) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(self.filename)

        var content = ""
        for alias in aliases {
            content += "#alias {\(alias.pattern)} {\(alias.replace)}"

            if let className = alias.className , className.count > 0 {
                content += " {\(className.lowercased())}"
            }

            content += "\n"
        }

        self.files.write(content, to: fileUrl)
    }
}

extension GameContext {
    
    static let regex = try? Regex("^#alias \\{(.*?)\\} \\{(.*?)\\}(?:\\s\\{(.*?)\\})?$", options: [.anchorsMatchLines, .caseInsensitive])
    
    func addAlias(alias: Alias) {
        self.aliases.append(alias)
    }
    
    func addAlias(alias: inout String) {
        guard let matches = GameContext.self.regex?.allMatches(&alias) else {
            return
        }

        for match in matches {
            if match.count > 2 {
                guard let pattern = match.valueAt(index: 1) else {
                    continue
                }
                
                let replace = match.valueAt(index: 2) ?? ""
                let className = match.valueAt(index: 3)

                addAlias(alias: Alias(pattern: pattern, replace: replace, className: className?.lowercased()))
            }
        }
    }
}
