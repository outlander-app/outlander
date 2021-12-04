//
//  ClassLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/9/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct ClassSetting {
    public var key: String
    public var value: Bool
}

class ClassSettings {
    private var _values: [String: Bool] = [:]

    func clear() {
        _values.removeAll()
    }

    func allOn() {
        for (key, _) in _values {
            _values[key] = true
        }
    }

    func allOff() {
        for (key, _) in _values {
            _values[key] = false
        }
    }

    func set(_ key: String, value: Bool) {
        _values[key.lowercased()] = value
    }

    func parse(_ values: String) {
        if values.hasPrefix("+") || values.hasPrefix("-") {
            let components = values.components(separatedBy: " ")

            for comp in components {
                if let s = parseSetting(comp) {
                    if s.key == "all" {
                        s.value ? allOn() : allOff()
                    } else {
                        set(s.key, value: s.value)
                    }
                }
            }

            return
        }

        if let s = parseToggleSetting(values) {
            if s.key == "all" {
                s.value ? allOn() : allOff()

            } else {
                set(s.key, value: s.value)
            }
        }
    }

    func all() -> [ClassSetting] {
        var items: [ClassSetting] = []

        for (key, value) in _values {
            items.append(ClassSetting(key: key, value: value))
        }

        return items.sorted {
            $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending
        }
    }

    func disabled() -> [String] {
        var items: [String] = []

        for (key, value) in _values {
            if !value {
                items.append(key)
            }
        }

        return items
    }

    func parseToggleSetting(_ val: String) -> ClassSetting? {
        let list = val.components(separatedBy: " ")

        if list.count < 2 {
            return nil
        }

        let key = list[0]
        let symbol = list[1]
        let value = symbol.toBool()

        guard !key.isEmpty else {
            return nil
        }

        return ClassSetting(key: key.lowercased(), value: value ?? false)
    }

    func parseSetting(_ val: String) -> ClassSetting? {
        let key = val[1...]
        let value = String(val[0]).toBool()

        guard !key.isEmpty else {
            return nil
        }

        return ClassSetting(key: key.lowercased(), value: value ?? false)
    }
}

class ClassLoader {
    let filename = "classes.cfg"

    let files: FileSystem

    let regex = try? Regex("^#class \\{(.*?)\\} \\{(.*?)\\}$", options: [.anchorsMatchLines, .caseInsensitive])

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        context.classes.clear()

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
            if match.count == 3 {
                guard let key = match.valueAt(index: 1) else {
                    continue
                }

                let val = (match.valueAt(index: 2) ?? "").toBool()

                context.classes.set(key, value: val ?? false)
            }
        }

        context.updateClassFilters()
    }

    func save(_ settings: ApplicationSettings, classes: ClassSettings) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        var content = ""
        for c in classes.all().sorted(by: { $0.key < $1.key }) {
            let val = c.value ? "on" : "off"
            content += "#class {\(c.key)} {\(val)}\n"
        }

        files.write(content, to: fileUrl)
    }
}
