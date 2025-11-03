//
//  MacroPreferencesModel.swift
//  Outlander
//
//  Created by Codex on 5/18/25.
//

import Carbon.HIToolbox
import Cocoa

struct MacroKeyDefinition: Hashable {
    let title: String
    let key: Key
}

enum MacroModifierGroup: Hashable {
    case none
    case command
    case option
    case control
    case shift

    var title: String {
        switch self {
        case .none: "None"
        case .command: "Command"
        case .option: "Option"
        case .control: "Control"
        case .shift: "Shift"
        }
    }

    var flags: NSEvent.ModifierFlags {
        switch self {
        case .none: []
        case .command: [.command]
        case .option: [.option]
        case .control: [.control]
        case .shift: [.shift]
        }
    }

    static func group(for flags: NSEvent.ModifierFlags) -> MacroModifierGroup? {
        if flags.isEmpty {
            return .none
        }
        switch flags {
        case [.command]:
            return .command
        case [.option]:
            return .option
        case [.control]:
            return .control
        case [.shift]:
            return .shift
        default:
            return nil
        }
    }

    static func groups(for category: MacroPreferencesCategory) -> [MacroModifierGroup] {
        switch category {
        case .letters:
            return [.command, .option, .control]
        case .keypad, .function:
            return [.none, .command, .option, .control, .shift]
        }
    }
}

struct MacroPreferencesStore {
    private(set) var values: [MacroModifierGroup: [Key: String]] = [:]
    private let reserved: [MacroModifierGroup: [Key: String]]
    let keyDefinitions: [MacroKeyDefinition]
    let modifierGroups: [MacroModifierGroup]

    init(category: MacroPreferencesCategory, context: GameContext?) {
        self.keyDefinitions = MacroPreferencesStore.buildKeyDefinitions(for: category)
        self.modifierGroups = MacroModifierGroup.groups(for: category)

        let defaults = MacroPreferencesStore.defaultValues(for: category)
        self.reserved = MacroPreferencesStore.reservedKeys(for: category)

        for group in modifierGroups {
            var entries: [Key: String] = [:]

            for definition in keyDefinitions {
                if reserved[group]?[definition.key] != nil {
                    continue
                }
                let existing = context?.macroAction(for: definition.key, modifiers: group.flags)
                let fallback = defaults[group]?[definition.key]
                entries[definition.key] = existing ?? fallback ?? ""
            }

            values[group] = entries
        }
    }

    func value(for group: MacroModifierGroup, key: Key) -> String {
        values[group]?[key] ?? ""
    }

    mutating func setValue(_ value: String, for group: MacroModifierGroup, key: Key) {
        guard values[group] != nil else {
            return
        }
        guard reserved[group]?[key] == nil else {
            return
        }
        values[group]?[key] = value
    }

    func isReserved(group: MacroModifierGroup, key: Key) -> Bool {
        reserved[group]?[key] != nil
    }

    func reservedLabel(group: MacroModifierGroup, key: Key) -> String? {
        reserved[group]?[key]
    }

    private static func buildKeyDefinitions(for category: MacroPreferencesCategory) -> [MacroKeyDefinition] {
        switch category {
        case .letters:
            return MacroPreferencesStore.letterKeys()
        case .keypad:
            return MacroPreferencesStore.keypadKeys()
        case .function:
            return MacroPreferencesStore.functionKeys()
        }
    }

    private static func letterKeys() -> [MacroKeyDefinition] {
        let pairs: [(String, Key)] = [
            ("A", .a), ("B", .b), ("C", .c), ("D", .d), ("E", .e), ("F", .f),
            ("G", .g), ("H", .h), ("I", .i), ("J", .j), ("K", .k), ("L", .l),
            ("M", .m), ("N", .n), ("O", .o), ("P", .p), ("Q", .q), ("R", .r),
            ("S", .s), ("T", .t), ("U", .u), ("V", .v), ("W", .w), ("X", .x),
            ("Y", .y), ("Z", .z),
        ]

        return pairs.map { MacroKeyDefinition(title: $0.0, key: $0.1) }
    }

    private static func keypadKeys() -> [MacroKeyDefinition] {
        let pairs: [(String, Key)] = [
            ("+", .keypadPlus),
            ("-", .keypadMinus),
            ("*", .keypadMultiply),
            ("/", .keypadDivide),
            ("=", .keypadEquals),
            ("Clear", .keypadClear),
            (".", .keypadDecimal),
            ("0", .keypad0),
            ("1", .keypad1),
            ("2", .keypad2),
            ("3", .keypad3),
            ("4", .keypad4),
            ("5", .keypad5),
            ("6", .keypad6),
            ("7", .keypad7),
            ("8", .keypad8),
            ("9", .keypad9),
        ]

        return pairs.map { MacroKeyDefinition(title: $0.0, key: $0.1) }
    }

    private static func functionKeys() -> [MacroKeyDefinition] {
        let pairs: [(String, Key)] = [
            ("Esc", .escape),
            ("F1", .f1),
            ("F2", .f2),
            ("F3", .f3),
            ("F4", .f4),
            ("F5", .f5),
            ("F6", .f6),
            ("F7", .f7),
            ("F8", .f8),
            ("F9", .f9),
            ("F10", .f10),
            ("F11", .f11),
            ("F12", .f12),
        ]

        return pairs.map { MacroKeyDefinition(title: $0.0, key: $0.1) }
    }

    private static func defaultValues(for category: MacroPreferencesCategory) -> [MacroModifierGroup: [Key: String]] {
        let allowedKeys = Set(buildKeyDefinitions(for: category).map { $0.key })
        let rawValues = MacroDefaults.valuesByModifierRaw(filteredBy: allowedKeys)
        var result: [MacroModifierGroup: [Key: String]] = [:]

        for (rawFlags, mapping) in rawValues {
            let flags = NSEvent.ModifierFlags(rawValue: rawFlags)
            guard let group = MacroModifierGroup.group(for: flags) else { continue }
            guard MacroModifierGroup.groups(for: category).contains(group) else { continue }
            guard !mapping.isEmpty else { continue }
            result[group] = mapping
        }

        return result
    }

    private static func reservedKeys(for category: MacroPreferencesCategory) -> [MacroModifierGroup: [Key: String]] {
        switch category {
        case .letters:
            let reservedKeys: Set<Key> = [.a, .c, .d, .e, .f, .g, .h, .i, .j, .q, .u, .v, .w, .x, .z]
            let label = "Reserved"
            return [.command: Dictionary(uniqueKeysWithValues: reservedKeys.map { ($0, label) })]
        case .keypad:
            return [:]
        case .function:
            let controlReserved: [Key: String] = [
                .f1: "System Reserved",
                .f2: "System Reserved",
                .f4: "System Reserved",
                .f5: "System Reserved",
                .f6: "System Reserved",
                .f7: "System Reserved",
            ]
            return [.control: controlReserved]
        }
    }

    private static func defaultKeypadMacros() -> [MacroModifierGroup: [Key: String]] {
        let baseDirections: [Key: String] = {
            var map: [Key: String] = [:]
            map[.keypad0] = "down"
            map[.keypad1] = "southwest"
            map[.keypad2] = "south"
            map[.keypad3] = "southeast"
            map[.keypad4] = "west"
            map[.keypad5] = "out"
            map[.keypad6] = "east"
            map[.keypad7] = "northwest"
            map[.keypad8] = "north"
            map[.keypad9] = "northeast"
            return map
        }()

        let noneGroup: [Key: String] = {
            var map: [Key: String] = [:]
            map[.keypadMultiply] = "exp"
            map[.keypadPlus] = "look"
            map[.keypadDecimal] = "up"
            map[.keypadDivide] = "health"
            for (key, direction) in baseDirections {
                map[key] = direction
            }
            return map
        }()

        let commandGroup: [Key: String] = {
            var map: [Key: String] = [:]
            map[.keypadDecimal] = "sneak up"
            map[.keypad0] = "sneak down"
            for (key, direction) in baseDirections where key != .keypad0 {
                map[key] = "sneak \(direction)"
            }
            return map
        }()

        let familiarGroup: [Key: String] = {
            var map: [Key: String] = [:]
            map[.keypadPlus] = "tell familiar to look"
            map[.keypadDecimal] = "tell familiar to go up"
            map[.keypad0] = "tell familiar to go down"
            for (key, direction) in baseDirections {
                map[key] = "tell familiar to go \(direction)"
            }
            return map
        }()

        return [
            .none: noneGroup,
            .command: commandGroup,
            .control: familiarGroup,
        ]
    }

    private static func defaultFunctionMacros() -> [MacroModifierGroup: [Key: String]] {
        var map: [Key: String] = [:]
        map[.escape] = "clear"
        return [.none: map]
    }
}
