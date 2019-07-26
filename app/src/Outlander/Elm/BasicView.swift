//
//  BasicView.swift
//  Outlander
//
//  Created by Joseph McBride on 7/22/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa

class OView : NSView {
    public var backgroundColor: NSColor?

    init() {
        super.init(frame: NSRect.zero)
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override var isFlipped: Bool {
        return true
    }

    override func draw(_ dirtyRect: NSRect) {
        self.wantsLayer = true
        self.layer?.backgroundColor = self.backgroundColor?.cgColor
    }
}

class VitalBarItemView : OView {

    public var text: String? {
        didSet {
            self.needsDisplay = true
        }
    }

    public var value: Double? {
       didSet {
           self.needsDisplay = true
       }
   }

    public var foregroundColor: NSColor = NSColor.white {
       didSet {
           self.needsDisplay = true
       }
   }

    override func draw(_ dirtyRect: NSRect) {

        super.draw(dirtyRect)

        if let text = self.text, let txt = NSString(utf8String: text) {
            let attributeDict: [NSAttributedString.Key : Any] = [
                .font: NSFont.init(name: "Menlo Bold", size: 11)!,
                .foregroundColor: self.foregroundColor,
            ]

            let size = txt.size(withAttributes: attributeDict)
            let point = NSPoint(
                x: (self.frame.size.width / 2) - (size.width / 2),
                y: (self.frame.size.height / 2) - (size.height / 2))
            txt.draw(at: point, withAttributes: attributeDict)
        }
    }
}
