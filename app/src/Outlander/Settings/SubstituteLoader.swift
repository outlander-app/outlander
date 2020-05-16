//
//  SubstituteLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct Substitute {
    var pattern: String
    var action: String
    var className: String?
}

extension GameContext {
    func activeSubs() -> [Substitute] {
        let disabled = self.classes.disabled()
        return self.substitutes
            .filter {h in (h.className == nil || h.className?.count == 0 || !disabled.contains(h.className!)) && h.pattern.count > 0}
            .sorted { $0.pattern.count > $1.pattern.count }
    }
}

class SubstituteLoader {
    let filename = "substitutes.cfg"

    let files: FileSystem

    let regex = try? Regex("^#subs \\{(.*?)\\} \\{(.*?)\\}(?:\\s\\{(.*?)\\})?$", options: [.anchorsMatchLines, .caseInsensitive])
    
    init(_ files:FileSystem) {
        self.files = files
    }

    func load(_ settings:ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(self.filename)

        context.substitutes.removeAll()

        guard let data = self.files.load(fileUrl) else {
            return
        }
        
        guard var content = String(data: data, encoding: .utf8) else {
            return
        }

        guard let matches = self.regex?.allMatches(&content) else {
            return
        }

        for match in matches {
            if match.count > 2 {
                guard let pattern = match.valueAt(index: 1) else {
                    continue
                }

                let action = match.valueAt(index: 2) ?? ""
                let className = match.valueAt(index: 3)

                context.substitutes.append(
                    Substitute(pattern: pattern, action: action, className: className?.lowercased())
                )
            }
        }
    }
    
    func save(_ settings: ApplicationSettings, subsitutes: [Substitute]) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(self.filename)

        var content = ""
        for sub in subsitutes {

            content += "#subs {\(sub.pattern)} {\(sub.action)}"

            if let className = sub.className, className.count > 0 {
                content += " {\(className)}"
            }
            
            content += "\n"
        }
        
        self.files.write(content, to: fileUrl)
    }
}
