//
//  AliasLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct Alias {
    static let aliasRegex = try? Regex("#alias \\{(.*?)\\} \\{(.*?)\\}(?:\\s\\{(.*?)\\})?", options: [.caseInsensitive])

    var pattern: String
    var replace: String
    var className: String?

    var description: String {
        return "#alias {\(pattern)} {\(replace)} {\(className ?? "")}"
    }

    static func from(alias: inout String) -> Alias? {
        guard let match = aliasRegex?.firstMatch(&alias) else {
            return nil
        }

        if match.count > 2 {
            guard let pattern = match.valueAt(index: 1) else {
                return nil
            }

            let replace = match.valueAt(index: 2) ?? ""
            let className = match.valueAt(index: 3)

            return Alias(pattern: pattern, replace: replace, className: className?.lowercased())
        }

        return nil
    }
}

class AliasLoader {
    let filename = "aliases.cfg"

    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        context.aliases.removeAll()

        guard let data = files.load(fileUrl) else {
            return
        }

        guard let content = String(data: data, encoding: .utf8) else {
            return
        }

        for var line in content.components(separatedBy: .newlines) {
            if let alias = Alias.from(alias: &line) {
                context.upsertAlias(alias: alias)
            }
        }
    }

    func save(_ settings: ApplicationSettings, aliases: [Alias]) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        var content = ""
        for alias in aliases {
            content += "#alias {\(alias.pattern)} {\(alias.replace)}"

            if let className = alias.className, className.count > 0 {
                content += " {\(className.lowercased())}"
            }

            content += "\n"
        }

        files.write(content, to: fileUrl)
    }
}

extension GameContext {
    func addAlias(alias: Alias) {
        aliases.append(alias)
    }

    @discardableResult
    func upsertAlias(alias: Alias) -> Bool {
        if let i = aliases.firstIndex(where: { $0.pattern == alias.pattern && $0.className == alias.className }) {
            aliases[i] = alias
            return false
        }
        addAlias(alias: alias)
        return true
    }
}
