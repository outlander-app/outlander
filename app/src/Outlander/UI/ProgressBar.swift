//
//  ProgressBar.swift
//  Outlander
//
//  Created by Joseph McBride on 12/11/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

class ProgressBar: NSView {
    @IBInspectable
    public var text: String = "Something 100%" {
        didSet {
            needsDisplay = true
        }
    }

    @IBInspectable
    public var value: Float = 100.0 {
        didSet {
            needsDisplay = true
        }
    }

//    @IBInspectable
//    public var backgroundColor = NSColor.blue {
//        didSet {
//            needsDisplay = true
//        }
//    }

    @IBInspectable
    public var foregroundColor = NSColor.white {
        didSet {
            needsDisplay = true
        }
    }

    @IBInspectable
    public var font = NSFont(name: "Menlo Bold", size: 11)! {
        didSet {
            self.needsDisplay = true
        }
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        let height = frame.size.height
        let width = frame.size.width
        let calcValue = Float(width) * (value * 0.01)
        let strokeWidth: Float = 0.0

        NSColor(hex: "#999999")?.setFill()
        NSMakeRect(0, 0, width, height).fill()

        backgroundColor?.setFill()
        NSMakeRect(CGFloat(strokeWidth), CGFloat(strokeWidth), CGFloat(calcValue - (strokeWidth * 2)), CGFloat(Float(height) - (strokeWidth * 2))).fill()

        super.draw(dirtyRect)

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: foregroundColor,
            NSAttributedString.Key.font: font,
        ]
        let str = NSAttributedString(string: text, attributes: attributes)
        let strSize = str.size()

        str.draw(at: NSPoint(x: (frame.size.width / 2.0) - (strSize.width / 2.0), y: (frame.size.height / 2.0) - (strSize.height / 2.0)))
    }
}
