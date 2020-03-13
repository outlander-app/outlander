//
//  ProgressBar.swift
//  Outlander
//
//  Created by Joseph McBride on 12/11/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa

class VitalsBar : NSView {

    var vitals:[String:ProgressBar] = [:]

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.autoresizesSubviews = true
        self.postsFrameChangedNotifications = true

        NotificationCenter.default.addObserver(self, selector: #selector(onFrameChanged(_:)), name: NSView.frameDidChangeNotification, object: nil)
    }

    override var isFlipped: Bool {
        get { return true }
    }

    override func awakeFromNib() {
        let height = self.frame.size.height;
        let width = self.frame.size.width / 5.0;
        var viewX:Float = 0.0;

        addVital(name: "health", text: "Health 100%", color: NSColor(hex: "#cc0000")!, frame:NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
        viewX += Float(width)

        addVital(name: "mana", text: "Mana 100%", color: NSColor(hex: "#00004B")!, frame:NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
        viewX += Float(width)

        addVital(name: "stamina", text: "Stamina 100%", color: NSColor(hex: "#004000")!, frame:NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
        viewX += Float(width)

        addVital(name: "concentration", text: "Concentration 100%", color: NSColor(hex: "#009999")!, frame:NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
        viewX += Float(width)

        addVital(name: "spirit", text: "Spirit 100%", color: NSColor(hex: "#400040")!, frame:NSRect(x: CGFloat(viewX), y: 0, width: width, height: height))
    }

    func addVital(name: String, text:String, color:NSColor, frame:NSRect) {
        let bar = ProgressBar(frame: frame)
        bar.text = text
        bar.backgroundColor = color

        self.vitals[name] = bar
        self.addSubview(bar)
    }

    func updateValue(vital:String, text:String, value:Int) {
        if let bar = self.vitals[vital] {
            DispatchQueue.main.async {
                bar.text = text
                bar.value = Float(value)
            }
        }
    }

    @objc func onFrameChanged(_ notification:Notification) {
        var viewX:Float = 0.0
        let width:Float = Float(self.frame.size.width) / Float(self.subviews.count)

        for view in subviews {
            view.setFrameSize(NSSize(width: CGFloat(width), height: view.frame.height))
            view.setFrameOrigin(NSPoint(x: CGFloat(viewX), y: view.frame.origin.y))
            viewX += width
        }
    }
}

class ProgressBar : NSView {

    @IBInspectable
    public var text: String = "Something 100%" {
        didSet {
            self.needsDisplay = true
        }
    }

    @IBInspectable
    public var value: Float = 100.0 {
        didSet {
            self.needsDisplay = true
        }
    }

    @IBInspectable
    public var backgroundColor: NSColor = NSColor.blue {
        didSet {
            self.needsDisplay = true
        }
    }

    @IBInspectable
    public var foregroundColor: NSColor = NSColor.white {
        didSet {
            self.needsDisplay = true
        }
    }

    @IBInspectable
    public var font: NSFont = NSFont(name: "Menlo Bold", size: 11)! {
        didSet {
            self.needsDisplay = true
        }
    }

    override var isFlipped: Bool {
        get { return true }
    }

    override func draw(_ dirtyRect: NSRect) {
        
        let height = self.frame.size.height;
        let width = self.frame.size.width;
        let calcValue = Float(width) * (self.value * 0.01)
        let strokeWidth:Float = 0.0

        NSColor(hex: "#999999")?.setFill()
        NSMakeRect(0, 0, width, height).fill()

        self.backgroundColor.setFill()
        NSMakeRect(CGFloat(strokeWidth), CGFloat(strokeWidth), CGFloat(calcValue-(strokeWidth * 2)), CGFloat(Float(height) - (strokeWidth * 2))).fill()

        super.draw(dirtyRect)

        let attributes:[NSAttributedString.Key:Any] = [
            NSAttributedString.Key.foregroundColor: foregroundColor,
            NSAttributedString.Key.font: font
        ]
        let str = NSAttributedString(string: self.text, attributes: attributes)
        let strSize = str.size()

        str.draw(at: NSPoint(x: (self.frame.size.width / 2.0) - (strSize.width / 2.0), y: (self.frame.size.height / 2.0) - (strSize.height / 2.0)))
    }
}
