//
//  OWindow.swift
//  Outlander
//
//  Created by Joe McBride on 12/5/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

class OWindow: NSWindow {
    @IBInspectable
    public var titleColor = NSColor(hex: "#f5f5f5")! {
        didSet {
            updateTitle()
        }
    }

    @IBInspectable
    public var titleBackgroundColor: NSColor? {
        didSet {
            updateTitle()
        }
    }

    @IBInspectable
    public var titleFont = NSFont(name: "Helvetica", size: 14)! {
        didSet {
            updateTitle()
        }
    }

    var gameContext: GameContext?

    var lastKeyWasMacro = false

    func registerKeyHandlers(_ gameContext: GameContext) {
        self.gameContext = gameContext

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.macroKeyDown(with: $0) {
                self.lastKeyWasMacro = true
                return nil
            }
            self.lastKeyWasMacro = false
            return $0
        }

        NSEvent.addLocalMonitorForEvents(matching: .keyUp) {
            if self.lastKeyWasMacro {
                self.lastKeyWasMacro = false
                return nil
            }
            return $0
        }
    }

    func macroKeyDown(with event: NSEvent) -> Bool {
        // handle keyDown only if current window has focus, i.e. is keyWindow
        guard NSApplication.shared.keyWindow === self else { return false }

        guard let found = gameContext?.findMacro(description: event.macro) else {
            return false
        }

        gameContext?.events.sendCommand(Command2(command: found.action))
        return true
    }

    func updateTitle() {
        guard let windowContentView = contentView else {
            return
        }
        guard let contentSuperView = windowContentView.superview else {
            return
        }

        let titleView = findViewInSubview(contentSuperView.subviews, ignoreView: windowContentView, test: { view in
            view is NSTextField
        })

        guard let titleText = titleView as? NSTextField else {
            return
        }

        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: titleColor,
        ]

        if let bg = titleBackgroundColor {
            attributes[.backgroundColor] = bg
        }

        titleText.attributedStringValue = NSAttributedString(string: title, attributes: attributes)
    }

    func findViewInSubview(_ subviews: [NSView], ignoreView: NSView, test: (NSView) -> Bool) -> NSView? {
        for v in subviews {
            if test(v) {
                return v
            } else if v != ignoreView {
                if let found = findViewInSubview(v.subviews as [NSView], ignoreView: ignoreView, test: test) {
                    return found
                }
            }
        }
        return nil
    }
}
