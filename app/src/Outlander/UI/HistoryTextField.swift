//
//  HistoryTextField.swift
//  Outlander
//
//  Created by Joseph McBride on 12/13/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

public class HistoryTextField: NSTextField {
    var currentHistoryIndex = -1

    public var history: [String] = []
    public var maxHistory = 30
    public var minCharacterLength = 3

    public var executeCommand: (String) -> Void = { _ in }

    @IBInspectable
    public var progress: Float = 0.0 {
        didSet {
            self.needsDisplay = true
        }
    }

    @IBInspectable
    public var progressColor: NSColor = NSColor(hex: "#003366")! {
        didSet {
            needsDisplay = true
        }
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public func draw(_ dirtyRect: NSRect) {
        var progressRect = bounds
        progressRect.size.width *= CGFloat(progress)

        progressColor.setFill()
        progressRect.fill(using: .sourceOver)

        super.draw(dirtyRect)
    }

    override public func performKeyEquivalent(with event: NSEvent) -> Bool {
        let s = event.charactersIgnoringModifiers!
        let s1 = s.unicodeScalars
        let s2 = s1[s1.startIndex].value
        let s3 = Int(s2)

        switch s3 {
        case NSUpArrowFunctionKey:
            previous()
        case NSDownArrowFunctionKey:
            next()
        default:
            break
        }

        return super.performKeyEquivalent(with: event)
    }

    func commitHistory() {
        currentHistoryIndex = -1

        var value = stringValue
        stringValue = ""

        if value.count == 0 {
            value = history.first ?? ""
        }

        if value.count > 0 {
            executeCommand(value)
        }

        if value.count < minCharacterLength || value == history.first { return }

        history.insert(value, at: 0)

        if history.count > maxHistory {
            history.removeLast()
        }
    }

    func previous() {
        var value = ""

        currentHistoryIndex += 1

        if currentHistoryIndex > -1 {
            if currentHistoryIndex >= history.count {
                currentHistoryIndex = -1
            } else {
                value = history[currentHistoryIndex]
            }
        }

        stringValue = value

        DispatchQueue.main.async {
            self.currentEditor()!.moveToEndOfDocument(nil)
        }
    }

    func next() {
        var value = ""
        let lastIndex = currentHistoryIndex

        if lastIndex == -1 {
            currentHistoryIndex = history.count
        }

        currentHistoryIndex -= 1

        if currentHistoryIndex > -1 {
            if lastIndex == 0 {
                currentHistoryIndex = -1
            } else {
                value = history[currentHistoryIndex]
            }
        }

        stringValue = value

        DispatchQueue.main.async {
            self.currentEditor()!.moveToEndOfDocument(nil)
        }
    }
}
