//
//  VitalsBar.swift
//  Outlander
//
//  Created by Joe McBride on 11/26/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

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

    var presetFor: (String) -> (NSColor, NSColor) = { _ in
        (NSColor.white, NSColor.blue)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        autoresizesSubviews = true
        postsFrameChangedNotifications = true

        NotificationCenter.default.addObserver(self, selector: #selector(onFrameChanged(_:)), name: NSView.frameDidChangeNotification, object: nil)

        presetFor = { color in
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
