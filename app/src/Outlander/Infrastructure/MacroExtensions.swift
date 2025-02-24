//
//  MacroExtensions.swift
//  Outlander
//
//  Created by Joe McBride on 10/25/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Carbon.HIToolbox
import Cocoa

public extension NSEvent {
    var macro: String {
        "\(modifierFlags.description)\(keyCode)"
    }
}

public extension NSEvent.ModifierFlags {
    var carbon: Int {
        var modifierFlags = 0

        if contains(.control) {
            modifierFlags |= controlKey
        }

        if contains(.option) {
            modifierFlags |= optionKey
        }

        if contains(.shift) {
            modifierFlags |= shiftKey
        }

        if contains(.command) {
            modifierFlags |= cmdKey
        }

        return modifierFlags
    }

    init(carbon: Int) {
        self.init()

        if carbon & controlKey == controlKey {
            insert(.control)
        }

        if carbon & optionKey == optionKey {
            insert(.option)
        }

        if carbon & shiftKey == shiftKey {
            insert(.shift)
        }

        if carbon & cmdKey == cmdKey {
            insert(.command)
        }
    }

    init(modifiers: String) {
        self.init()

        let modList = modifiers.map { String($0) }

        if modList.contains("⌃") {
            insert(.control)
        }

        if modList.contains("⌥") {
            insert(.option)
        }

        if modList.contains("⇧") {
            insert(.shift)
        }

        if modList.contains("⌘") {
            insert(.command)
        }
    }
}

extension NSEvent.ModifierFlags: @retroactive CustomStringConvertible {
    public var description: String {
        var description = ""

        if contains(.control) {
            description += "⌃"
        }

        if contains(.option) {
            description += "⌥"
        }

        if contains(.shift) {
            description += "⇧"
        }

        if contains(.command) {
            description += "⌘"
        }

        return description
    }
}
