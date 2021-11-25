//
//  HighlightLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct Highlight {
    var foreColor: String
    var backgroundColor: String
    var pattern: String
    var className: String
    var soundFile: String
}

class Highlights {
    private var lights: [Highlight]
    private var cache: [Highlight] = []

    init(subs: [Highlight] = []) {
        lights = subs
    }

    var count: Int {
        lights.count
    }

    func replace(with subs: [Highlight]) {
        lights = subs
    }

    func add(_ sub: Highlight) {
        lights.append(sub)
    }

    func all() -> [Highlight] {
        lights
    }

    func active() -> [Highlight] {
        cache
    }

    func updateActiveCache(with disabled: [String]) {
        cache = lights
            .filter { h in (h.className.count == 0 || !disabled.contains(h.className)) && h.pattern.count > 0 }
            .sorted { $0.pattern.count > $1.pattern.count }
    }

    func removeAll() {
        lights.removeAll()
    }
}

class HighlightLoader {
    let filename = "highlights.cfg"

    let files: FileSystem

    let regex = try? Regex("^#highlight \\{(.*?)\\} \\{(.*?)\\}(?:\\s\\{(.*?)\\})?(?:\\s\\{(.*?)\\})?$", options: [.anchorsMatchLines, .caseInsensitive])

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        context.highlights.removeAll()

        guard let data = files.load(fileUrl) else {
            return
        }

        guard var content = String(data: data, encoding: .utf8) else {
            return
        }

        guard let matches = regex?.allMatches(&content) else {
            return
        }

        for match in matches {
            if match.count > 2 {
                guard var color = match.valueAt(index: 1) else {
                    continue
                }

                var backgroundColor = ""
                let colors = color.components(separatedBy: ",")

                if colors.count > 1 {
                    color = colors[0].trimmingCharacters(in: NSCharacterSet.whitespaces)
                    backgroundColor = colors[1].trimmingCharacters(in: NSCharacterSet.whitespaces)
                }

                let pattern = match.valueAt(index: 2) ?? ""
                let className = match.valueAt(index: 3) ?? ""
                let soundFile = match.valueAt(index: 4) ?? ""

                context.highlights.add(
                    Highlight(
                        foreColor: color.lowercased(),
                        backgroundColor: backgroundColor.lowercased(),
                        pattern: pattern,
                        className: className.lowercased(),
                        soundFile: soundFile
                    )
                )
            }
        }

        context.highlights.updateActiveCache(with: context.classes.disabled())
    }

    func save(_ settings: ApplicationSettings, highlights: [Highlight]) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        var content = ""
        for highlight in highlights {
            var color = highlight.foreColor

            if highlight.backgroundColor.count > 0 {
                color += ",\(highlight.backgroundColor)"
            }

            content += "#highlight {\(color)} {\(highlight.pattern)}"

            if highlight.className.count > 0 {
                content += " {\(highlight.className.lowercased())}"
            }

            if highlight.soundFile.count > 0 {
                if highlight.className.count == 0 {
                    content += " {}"
                }

                content += " {\(highlight.soundFile)}"
            }

            content += "\n"
        }

        files.write(content, to: fileUrl)
    }
}
