//
//  OView.swift
//  Outlander
//
//  Created by Joe McBride on 12/5/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

class OView: NSView {
    var name: String = ""

    @IBInspectable var backgroundColor: NSColor? {
        didSet {
            needsDisplay = true
        }
    }

    @IBInspectable var borderColor: NSColor? = NSColor(hex: "#cccccc") {
        didSet {
            needsDisplay = true
        }
    }

    // dynamic allows for animation
    @IBInspectable dynamic var borderWidth: CGFloat = 0 {
        didSet {
            needsDisplay = true
        }
    }

    @IBInspectable dynamic var cornerRadius: CGFloat = 0 {
        didSet {
            needsDisplay = true
        }
    }

    @IBInspectable var displayBorder: Bool = true {
        didSet {
            needsDisplay = true
        }
    }

    override var wantsUpdateLayer: Bool {
        true
    }

    init() {
        super.init(frame: NSRect.zero)
    }

    init(color: NSColor, frame: NSRect) {
        super.init(frame: frame)
        backgroundColor = color
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override var isFlipped: Bool {
        true
    }

    func reOrderView() {}

    func index(of key: String) -> Int {
        guard let idx = subviews.firstIndex(where: { view in
            (view as? OView)?.name == key
        }) else {
            return 0
        }

        return idx + 1
    }

    override func animation(forKey key: NSAnimatablePropertyKey) -> Any? {
        switch key {
        case "borderWidth":
            return CABasicAnimation()
        default:
            return super.animation(forKey: key)
        }
    }

    override func updateLayer() {
        guard let layer = layer else { return }

        layer.backgroundColor = backgroundColor?.cgColor
        layer.cornerRadius = cornerRadius

        if displayBorder {
            layer.borderColor = borderColor?.cgColor
            layer.borderWidth = borderWidth
        } else {
            layer.borderWidth = CGFloat.zero
        }
    }
}
