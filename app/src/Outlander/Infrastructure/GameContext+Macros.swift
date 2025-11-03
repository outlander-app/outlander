//
//  GameContext+Macros.swift
//  Outlander
//
//  Created by Codex on 5/18/25.
//

import Cocoa

extension Macro {
    func matches(key: Key, modifiers: NSEvent.ModifierFlags) -> Bool {
        carbonKeyCode == key.rawValue && self.modifiers == modifiers
    }
}

extension GameContext {
    func macroAction(for key: Key, modifiers: NSEvent.ModifierFlags) -> String? {
        macroEntry(for: key, modifiers: modifiers)?.macro.action
    }

    func setMacro(action: String?, for key: Key, modifiers: NSEvent.ModifierFlags) {
        let normalized = action?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let entry = macroEntry(for: key, modifiers: modifiers) {
            macros.removeValue(forKey: entry.identifier)
        }

        guard let normalized, !normalized.isEmpty else {
            return
        }

        let macro = Macro(key: key, modifiers: modifiers, action: normalized)
        macros[macro.description] = macro
    }

    private func macroEntry(for key: Key, modifiers: NSEvent.ModifierFlags) -> (identifier: String, macro: Macro)? {
        for (identifier, macro) in macros where macro.matches(key: key, modifiers: modifiers) {
            return (identifier, macro)
        }
        return nil
    }
}
