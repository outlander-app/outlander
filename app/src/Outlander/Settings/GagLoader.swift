//
//  GagLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct Gag: CustomStringConvertible {
    static let gagRegex = try? Regex("#gag \\{(.*?)\\}(?:\\s\\{(.*?)\\})?", options: [.anchorsMatchLines, .caseInsensitive])
    
    var pattern: String
    var className: String
    
    var description: String {
        return "#gag {\(self.pattern)} {\(self.className)}"
    }
    
    static func from(gag: inout String) -> Gag? {
        guard let match = gagRegex?.firstMatch(&gag) else {
            return nil
        }
        
        if match.count == 3 {
            guard let pattern = match.valueAt(index: 1) else {
                return nil
            }

            let className = match.valueAt(index: 2) ?? ""
            return Gag(pattern: pattern, className: className.lowercased())
        }
        
        return nil
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
        
        guard let content = String(data: data, encoding: .utf8) else {
            return
        }

        for var line in content.components(separatedBy: .newlines) {
            if let gag = Gag.from(gag: &line) {
                context.upsertGag(gag: gag)
            }
        }
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
    
    func addGag(gag: Gag) {
        self.gags.append(gag)
    }
    
    @discardableResult
    func upsertGag(gag: Gag) -> Bool {
        // Nothing to update
        if (self.gags.firstIndex(where: { $0.pattern == gag.pattern && $0.className == gag.className }) != nil) {
            return false
        }
        self.addGag(gag: gag)
        return true
    }
}
