//
//  ProgressBar.swift
//  Outlander
//
//  Created by Joseph McBride on 12/11/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

class VitalsBar: NSView {
    var vitals: [String: ProgressBar] = [:]

    var enabled: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.updateColors()
            }
        }
    }

    @IBInspectable
    public var disabledBackgroundColor = NSColor.lightGray {
        didSet {
            DispatchQueue.main.async {
                self.updateColors()
            }
        }
    }

    @IBInspectable
    public var disabledForegroundColor = NSColor.darkGray {
        didSet {
            DispatchQueue.main.async {
                self.updateColors()
            }
        }
    }

    var presetFor: (String) -> (NSColor, NSColor) = {color in
        (NSColor.white, NSColor.blue)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        autoresizesSubviews = true
        postsFrameChangedNotifications = true

        NotificationCenter.default.addObserver(self, selector: #selector(onFrameChanged(_:)), name: NSView.frameDidChangeNotification, object: nil)
        
        presetFor = {color in
            if !self.enabled {
                return (self.disabledForegroundColor, self.disabledBackgroundColor)
            }

            switch color {
            case "health":
                return (NSColor.white, NSColor(hex: "#cc0000")!)
            case "mana":
                return (NSColor.white, NSColor(hex: "#00004B")!)
            case "stamina":
                return (NSColor.white, NSColor(hex: "#004000")!)
            case "concentration":
                return (NSColor.white, NSColor(hex: "#009999")!)
            case "spirit":
                return (NSColor.white, NSColor(hex: "#400040")!)
            default:
                return (NSColor.white, NSColor.blue)
            }
        }
    }

    override var isFlipped: Bool { true }

    override func awakeFromNib() {
        let height = frame.size.height
        let width = frame.size.width / 5.0
        var viewX: Float = 0.0

        addVital(name: "health", text: "Health 100%", frame: NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
        viewX += Float(width)

        addVital(name: "mana", text: "Mana 100%", frame: NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
        viewX += Float(width)

        addVital(name: "stamina", text: "Stamina 100%", frame: NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
        viewX += Float(width)

        addVital(name: "concentration", text: "Concentration 100%", frame: NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
        viewX += Float(width)

        addVital(name: "spirit", text: "Spirit 100%", frame: NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
    }

    func addVital(name: String, text: String, frame: NSRect) {
        let bar = ProgressBar(frame: frame)
        bar.text = text

        let (fore, back) = presetFor(name)

        bar.foregroundColor = fore
        bar.backgroundColor = back

        vitals[name] = bar
        addSubview(bar)
    }

    func updateValue(vital: String, text: String, value: Int) {
        if let bar = vitals[vital] {
            DispatchQueue.main.async {
                bar.text = text
                bar.value = Float(value)
            }
        }
    }

    func updateColors() {
        for vital in vitals {
            DispatchQueue.main.async {
                let (fore, back) = self.presetFor(vital.key)
                vital.value.foregroundColor = fore
                vital.value.backgroundColor = back
            }
        }
    }

    @objc func onFrameChanged(_: Notification) {
        var viewX: Float = 0.0
        let width = Float(frame.size.width) / Float(subviews.count)

        for view in subviews {
            view.setFrameSize(NSSize(width: CGFloat(width), height: view.frame.height))
            view.setFrameOrigin(NSPoint(x: CGFloat(viewX), y: view.frame.origin.y))
            viewX += width
        }
    }
}

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

    @IBInspectable
    public var backgroundColor = NSColor.blue {
        didSet {
            needsDisplay = true
        }
    }

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

        backgroundColor.setFill()
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
