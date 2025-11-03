//
//  MacroLoader.swift
//  Outlander
//
//  Created by Joe McBride on 10/15/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Carbon.HIToolbox
import Cocoa

public struct Key: Hashable, RawRepresentable, CustomStringConvertible {
    public static let a = Self(kVK_ANSI_A)
    public static let b = Self(kVK_ANSI_B)
    public static let c = Self(kVK_ANSI_C)
    public static let d = Self(kVK_ANSI_D)
    public static let e = Self(kVK_ANSI_E)
    public static let f = Self(kVK_ANSI_F)
    public static let g = Self(kVK_ANSI_G)
    public static let h = Self(kVK_ANSI_H)
    public static let i = Self(kVK_ANSI_I)
    public static let j = Self(kVK_ANSI_J)
    public static let k = Self(kVK_ANSI_K)
    public static let l = Self(kVK_ANSI_L)
    public static let m = Self(kVK_ANSI_M)
    public static let n = Self(kVK_ANSI_N)
    public static let o = Self(kVK_ANSI_O)
    public static let p = Self(kVK_ANSI_P)
    public static let q = Self(kVK_ANSI_Q)
    public static let r = Self(kVK_ANSI_R)
    public static let s = Self(kVK_ANSI_S)
    public static let t = Self(kVK_ANSI_T)
    public static let u = Self(kVK_ANSI_U)
    public static let v = Self(kVK_ANSI_V)
    public static let w = Self(kVK_ANSI_W)
    public static let x = Self(kVK_ANSI_X)
    public static let y = Self(kVK_ANSI_Y)
    public static let z = Self(kVK_ANSI_Z)

    public static let zero = Self(kVK_ANSI_0)
    public static let one = Self(kVK_ANSI_1)
    public static let two = Self(kVK_ANSI_2)
    public static let three = Self(kVK_ANSI_3)
    public static let four = Self(kVK_ANSI_4)
    public static let five = Self(kVK_ANSI_5)
    public static let six = Self(kVK_ANSI_6)
    public static let seven = Self(kVK_ANSI_7)
    public static let eight = Self(kVK_ANSI_8)
    public static let nine = Self(kVK_ANSI_9)

    public static let capsLock = Self(kVK_CapsLock)
    public static let shift = Self(kVK_Shift)
    public static let function = Self(kVK_Function)
    public static let control = Self(kVK_Control)
    public static let option = Self(kVK_Option)
    public static let command = Self(kVK_Command)
    public static let rightCommand = Self(kVK_RightCommand)
    public static let rightOption = Self(kVK_RightOption)
    public static let rightControl = Self(kVK_RightControl)
    public static let rightShift = Self(kVK_RightShift)

    public static let `return` = Self(kVK_Return)
    public static let backslash = Self(kVK_ANSI_Backslash)
    public static let backtick = Self(kVK_ANSI_Grave)
    public static let comma = Self(kVK_ANSI_Comma)
    public static let equal = Self(kVK_ANSI_Equal)
    public static let minus = Self(kVK_ANSI_Minus)
    public static let period = Self(kVK_ANSI_Period)
    public static let quote = Self(kVK_ANSI_Quote)
    public static let semicolon = Self(kVK_ANSI_Semicolon)
    public static let slash = Self(kVK_ANSI_Slash)
    public static let space = Self(kVK_Space)
    public static let tab = Self(kVK_Tab)
    public static let leftBracket = Self(kVK_ANSI_LeftBracket)
    public static let rightBracket = Self(kVK_ANSI_RightBracket)
    public static let pageUp = Self(kVK_PageUp)
    public static let pageDown = Self(kVK_PageDown)
    public static let home = Self(kVK_Home)
    public static let end = Self(kVK_End)
    public static let upArrow = Self(kVK_UpArrow)
    public static let rightArrow = Self(kVK_RightArrow)
    public static let downArrow = Self(kVK_DownArrow)
    public static let leftArrow = Self(kVK_LeftArrow)
    public static let escape = Self(kVK_Escape)
    public static let delete = Self(kVK_Delete)
    public static let deleteForward = Self(kVK_ForwardDelete)
    public static let help = Self(kVK_Help)
    public static let mute = Self(kVK_Mute)
    public static let volumeUp = Self(kVK_VolumeUp)
    public static let volumeDown = Self(kVK_VolumeDown)

    public static let f1 = Self(kVK_F1)
    public static let f2 = Self(kVK_F2)
    public static let f3 = Self(kVK_F3)
    public static let f4 = Self(kVK_F4)
    public static let f5 = Self(kVK_F5)
    public static let f6 = Self(kVK_F6)
    public static let f7 = Self(kVK_F7)
    public static let f8 = Self(kVK_F8)
    public static let f9 = Self(kVK_F9)
    public static let f10 = Self(kVK_F10)
    public static let f11 = Self(kVK_F11)
    public static let f12 = Self(kVK_F12)
    public static let f13 = Self(kVK_F13)
    public static let f14 = Self(kVK_F14)
    public static let f15 = Self(kVK_F15)
    public static let f16 = Self(kVK_F16)
    public static let f17 = Self(kVK_F17)
    public static let f18 = Self(kVK_F18)
    public static let f19 = Self(kVK_F19)
    public static let f20 = Self(kVK_F20)

    public static let keypad0 = Self(kVK_ANSI_Keypad0)
    public static let keypad1 = Self(kVK_ANSI_Keypad1)
    public static let keypad2 = Self(kVK_ANSI_Keypad2)
    public static let keypad3 = Self(kVK_ANSI_Keypad3)
    public static let keypad4 = Self(kVK_ANSI_Keypad4)
    public static let keypad5 = Self(kVK_ANSI_Keypad5)
    public static let keypad6 = Self(kVK_ANSI_Keypad6)
    public static let keypad7 = Self(kVK_ANSI_Keypad7)
    public static let keypad8 = Self(kVK_ANSI_Keypad8)
    public static let keypad9 = Self(kVK_ANSI_Keypad9)
    public static let keypadClear = Self(kVK_ANSI_KeypadClear)
    public static let keypadDecimal = Self(kVK_ANSI_KeypadDecimal)
    public static let keypadDivide = Self(kVK_ANSI_KeypadDivide)
    public static let keypadEnter = Self(kVK_ANSI_KeypadEnter)
    public static let keypadEquals = Self(kVK_ANSI_KeypadEquals)
    public static let keypadMinus = Self(kVK_ANSI_KeypadMinus)
    public static let keypadMultiply = Self(kVK_ANSI_KeypadMultiply)
    public static let keypadPlus = Self(kVK_ANSI_KeypadPlus)

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    private init(_ value: Int) {
        self.init(rawValue: value)
    }

    public var description: String {
        keyToString[self] ?? "unknown"
    }
}

private var keyToString: [Key: String] = [
    .a: "a",
    .b: "b",
    .c: "c",
    .d: "d",
    .e: "e",
    .f: "f",
    .g: "g",
    .h: "h",
    .i: "i",
    .j: "j",
    .k: "k",
    .l: "l",
    .m: "m",
    .n: "n",
    .o: "o",
    .p: "p",
    .q: "q",
    .r: "r",
    .s: "s",
    .t: "t",
    .u: "u",
    .v: "v",
    .w: "w",
    .x: "x",
    .y: "y",
    .z: "z",

    .zero: "0",
    .one: "1",
    .two: "2",
    .three: "3",
    .four: "4",
    .five: "5",
    .six: "6",
    .seven: "7",
    .eight: "8",
    .nine: "9",

    .capsLock: "capsLock",
    .shift: "shift",
    .function: "function",
    .control: "control",
    .option: "option",
    .command: "command",
    .rightCommand: "rightCommand",
    .rightOption: "rightOption",
    .rightControl: "rightControl",
    .rightShift: "rightShift",

    .return: "return",
    .backslash: "backslash",
    .backtick: "backtick",
    .comma: "comma",
    .equal: "equal",
    .minus: "minus",
    .period: "period",
    .quote: "quote",
    .semicolon: "semicolon",
    .slash: "slash",
    .space: "space",
    .tab: "tab",
    .leftBracket: "[",
    .rightBracket: "]",
    .pageUp: "pageUp",
    .pageDown: "pageDown",
    .home: "home",
    .end: "end",
    .upArrow: "upArrow",
    .rightArrow: "rightArrow",
    .downArrow: "downArrow",
    .leftArrow: "leftArrow",
    .escape: "escape",
    .delete: "delete",
    .deleteForward: "deleteForward",
    .help: "help",
    .mute: "mute",
    .volumeUp: "volumeUp",
    .volumeDown: "volumeDown",

    .f1: "F1",
    .f2: "F2",
    .f3: "F3",
    .f4: "F4",
    .f5: "F5",
    .f6: "F6",
    .f7: "F7",
    .f8: "F8",
    .f9: "F9",
    .f10: "F10",
    .f11: "F11",
    .f12: "F12",
    .f13: "F13",
    .f14: "F14",
    .f15: "F15",
    .f16: "F16",
    .f17: "F17",
    .f18: "F18",
    .f19: "F19",
    .f20: "F20",

    .keypad0: "keypad0",
    .keypad1: "keypad1",
    .keypad2: "keypad2",
    .keypad3: "keypad3",
    .keypad4: "keypad4",
    .keypad5: "keypad5",
    .keypad6: "keypad6",
    .keypad7: "keypad7",
    .keypad8: "keypad8",
    .keypad9: "keypad9",
    .keypadClear: "keypadClear",
    .keypadDecimal: "keypadDecimal",
    .keypadDivide: "keypadDivide",
    .keypadEnter: "keypadEnter",
    .keypadEquals: "keypadEquals",
    .keypadMinus: "keypadMinus",
    .keypadMultiply: "keypadMultiply",
    .keypadPlus: "keypadPlus",
]

class Macro: CustomStringConvertible {
    static let macroRegex = try? Regex("^#macro \\{(.*)\\} \\{(.*)\\}$", options: [.anchorsMatchLines, .caseInsensitive])
    static let modifiersCharacterSet = CharacterSet(charactersIn: "⌃⌥⇧⌘ ")

    static func normalizeModifiers(_ carbonModifiers: Int) -> Int {
        NSEvent.ModifierFlags(carbon: carbonModifiers).carbon
    }

    var carbonKeyCode: Int
    var carbonModifiers: Int
    var action: String

    var key: Key? { Key(rawValue: carbonKeyCode) }
    var modifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(carbon: carbonModifiers) }

    var description: String {
        "\(NSEvent.ModifierFlags(carbon: carbonModifiers))\(carbonKeyCode)"
    }

    public convenience init(_ keys: String, action: String) {
        let modifiers = NSEvent.ModifierFlags(modifiers: keys)
        var carbonKeys = Int(keys.trimmingCharacters(in: Self.modifiersCharacterSet))
        if carbonKeys == nil {
            carbonKeys = 0
            print("could not figure out \(keys)")
        }

        self.init(carbonKeyCode: carbonKeys!, carbonModifiers: modifiers.carbon, action: action)
    }

    public convenience init(key: Key, modifiers: NSEvent.ModifierFlags = [], action: String = "") {
        self.init(
            carbonKeyCode: key.rawValue,
            carbonModifiers: modifiers.carbon,
            action: action
        )
    }

    public init(carbonKeyCode: Int, carbonModifiers: Int = 0, action: String) {
        self.carbonKeyCode = carbonKeyCode
        self.carbonModifiers = Self.normalizeModifiers(carbonModifiers)
        self.action = action
    }

    static func from(_ input: inout String) -> Macro? {
//        print("checking \(input)")
        guard input.utf8.count > 0 else {
            return nil
        }

        guard let match = macroRegex?.firstMatch(&input) else {
            return nil
        }

        if match.count == 3 {
            guard let keys = match.valueAt(index: 1) else {
                return nil
            }

            let action = match.valueAt(index: 2) ?? ""
            let macro = Macro(keys, action: action)
            return macro
        }

        return nil
    }
}

class MacroLoader {
    let filename = "macros.cfg"

    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, context: GameContext) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        context.macros.removeAll()

        guard let data = files.load(fileUrl), let content = String(data: data, encoding: .utf8) else {
            applyDefaults(context: context, settings: settings)
            return
        }

        for var line in content.components(separatedBy: .newlines) {
            guard !line.isEmpty else {
                continue
            }
            if let macro = Macro.from(&line) {
                context.macros[macro.description] = macro
            } else {
                context.events2.echoError("Invalid macro: \(line)")
            }
        }

        if context.macros.isEmpty {
            applyDefaults(context: context, settings: settings)
        }
    }

    func save(_ settings: ApplicationSettings, macros: [String: Macro]) {
        let fileUrl = settings.currentProfilePath.appendingPathComponent(filename)

        var content = ""
        for macro in macros.sorted(by: {
            if $0.value.carbonKeyCode == $1.value.carbonKeyCode { return $0.value.carbonModifiers < $1.value.carbonModifiers }
            return $0.value.carbonKeyCode < $1.value.carbonKeyCode
        }) {
            content += "#macro {\(macro.key)} {\(macro.value.action)}\n"
        }

        files.write(content, to: fileUrl)
    }

    private func applyDefaults(context: GameContext, settings: ApplicationSettings) {
        let defaults = MacroDefaults.defaultMacros()
        for macro in defaults {
            context.macros[macro.description] = macro
        }
        save(settings, macros: context.macros)
    }
}

extension GameContext {
    func findMacro(description: String) -> Macro? {
        macros[description]
    }
}
