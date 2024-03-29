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

class Substitutes {
    private let lock = NSLock()
    private var subs: [Substitute]
    private var cache: [Substitute] = []

    init(subs: [Substitute] = []) {
        self.subs = subs
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return subs.count
    }

    func replace(with subs: [Substitute]) {
        self.subs = subs
    }

    func add(_ sub: Substitute) {
        lock.lock()
        defer { lock.unlock() }
        subs.append(sub)
    }

    func all() -> [Substitute] {
        lock.lock()
        defer { lock.unlock() }
        return subs
    }

    func active() -> [Substitute] {
        lock.lock()
        defer { lock.unlock() }
        return cache
    }

    func updateActiveCache(with disabled: [String]) {
        lock.lock()
        defer { lock.unlock() }
        cache = subs
            .filter { h in (h.className == nil || h.className?.count == 0 || !disabled.contains(h.className!)) && h.pattern.count > 0 }
            .sorted { $0.pattern.count > $1.pattern.count }
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        subs.removeAll()
    }
}

class SubstituteLoader {
    let filename = "substitutes.cfg"

    let files: FileSystem

    let regex = try? Regex("^#subs \\{(.*?)\\} \\{(.*?)\\}(?:\\s\\{(.*?)\\})?$", options: [.anchorsMatchLines, .caseInsensitive])

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        context.substitutes.removeAll()

        guard let data = files.load(fileUrl) else {
            return
        }

        guard let content = String(data: data, encoding: .utf8) else {
            return
        }

        guard let matches = regex?.allMatches(content) else {
            return
        }

        for match in matches {
            if match.count > 2 {
                guard let pattern = match.valueAt(index: 1) else {
                    continue
                }

                let action = match.valueAt(index: 2) ?? ""
                let className = match.valueAt(index: 3)

                context.substitutes.add(
                    Substitute(pattern: pattern, action: action, className: className?.lowercased())
                )
            }
        }

        context.substitutes.updateActiveCache(with: context.classes.disabled())
    }

    func save(_ settings: ApplicationSettings, subsitutes: [Substitute]) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        var content = ""
        for sub in subsitutes {
            content += "#subs {\(sub.pattern)} {\(sub.action)}"

            if let className = sub.className, className.count > 0 {
                content += " {\(className)}"
            }

            content += "\n"
        }

        files.write(content, to: fileUrl)
    }
}
