//
//  MacroDefaults.swift
//  Outlander
//
//  Created by Codex on 5/18/25.
//

import Cocoa

struct MacroDefaultEntry {
    let key: Key
    let modifiers: NSEvent.ModifierFlags
    let action: String
}

enum MacroDefaults {
    static let entries: [MacroDefaultEntry] = {
        var list: [MacroDefaultEntry] = []

        func add(_ key: Key, _ modifiers: NSEvent.ModifierFlags = [], _ action: String) {
            list.append(MacroDefaultEntry(key: key, modifiers: modifiers, action: action))
        }

        // Base keypad navigation (no modifier)
        add(.keypadMultiply, [], "exp")
        add(.keypadPlus, [], "look")
        add(.keypadDecimal, [], "up")
        add(.keypadDivide, [], "health")
        add(.keypad0, [], "down")
        add(.keypad1, [], "southwest")
        add(.keypad2, [], "south")
        add(.keypad3, [], "southeast")
        add(.keypad4, [], "west")
        add(.keypad5, [], "out")
        add(.keypad6, [], "east")
        add(.keypad7, [], "northwest")
        add(.keypad8, [], "north")
        add(.keypad9, [], "northeast")

        // Command keypad (sneak)
        add(.keypadDecimal, [.command], "sneak up")
        add(.keypad0, [.command], "sneak down")
        add(.keypad1, [.command], "sneak southwest")
        add(.keypad2, [.command], "sneak south")
        add(.keypad3, [.command], "sneak southeast")
        add(.keypad4, [.command], "sneak west")
        add(.keypad5, [.command], "sneak out")
        add(.keypad6, [.command], "sneak east")
        add(.keypad7, [.command], "sneak northwest")
        add(.keypad8, [.command], "sneak north")
        add(.keypad9, [.command], "sneak northeast")

        // Control keypad (familiar)
        add(.keypadPlus, [.control], "tell familiar to look")
        add(.keypadDecimal, [.control], "tell familiar to go up")
        add(.keypad0, [.control], "tell familiar to go down")
        add(.keypad1, [.control], "tell familiar to go southwest")
        add(.keypad2, [.control], "tell familiar to go south")
        add(.keypad3, [.control], "tell familiar to go southeast")
        add(.keypad4, [.control], "tell familiar to go west")
        add(.keypad5, [.control], "tell familiar to go out")
        add(.keypad6, [.control], "tell familiar to go east")
        add(.keypad7, [.control], "tell familiar to go northwest")
        add(.keypad8, [.control], "tell familiar to go north")
        add(.keypad9, [.control], "tell familiar to go northeast")

        // Function defaults
        add(.escape, [], "clear")

        return list
    }()

    static func defaultMacros() -> [Macro] {
        entries.map { Macro(key: $0.key, modifiers: $0.modifiers, action: $0.action) }
    }

    static func valuesByModifierRaw(filteredBy keys: Set<Key>) -> [UInt: [Key: String]] {
        var result: [UInt: [Key: String]] = [:]
        for entry in entries where keys.contains(entry.key) {
            let raw = entry.modifiers.rawValue
            if result[raw] == nil {
                result[raw] = [:]
            }
            result[raw]?[entry.key] = entry.action
        }
        return result
    }
}
