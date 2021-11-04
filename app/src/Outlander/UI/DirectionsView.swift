//
//  DirectionsView.swift
//  Outlander
//
//  Created by Joe McBride on 10/29/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

class IndicatorView: NSView {
    var image = NSImage(named: "bleeding")

    @IBInspectable var imageName: String = "bleeding" {
        didSet {
            image = NSImage(named: imageName)
            needsDisplay = true
        }
    }

    @IBInspectable var toggle: Bool = true {
        didSet {
            needsDisplay = true
        }
    }

    override public var isFlipped: Bool {
        true
    }

    override public func draw(_: NSRect) {
        if toggle {
            image?.draw(in: bounds)
        }
    }
}

class DirectionsView: NSView {
    var dir = NSImage(named: "directions-dark")
    var north = NSImage(named: "north")
    var south = NSImage(named: "south")
    var east = NSImage(named: "east")
    var west = NSImage(named: "west")
    var northeast = NSImage(named: "northeast")
    var northwest = NSImage(named: "northwest")
    var southeast = NSImage(named: "southeast")
    var southwest = NSImage(named: "southwest")
    var out = NSImage(named: "out")
    var up = NSImage(named: "up")
    var down = NSImage(named: "down")

    var availableDirections: [String] = [] {
        didSet {
            needsDisplay = true
        }
    }

    override public var isFlipped: Bool {
        true
    }

    override public func draw(_: NSRect) {
        dir?.draw(in: bounds)

        if availableDirections.contains("north") {
            north?.draw(in: bounds)
        }

        if availableDirections.contains("south") {
            south?.draw(in: bounds)
        }

        if availableDirections.contains("east") {
            east?.draw(in: bounds)
        }

        if availableDirections.contains("west") {
            west?.draw(in: bounds)
        }

        if availableDirections.contains("northeast") {
            northeast?.draw(in: bounds)
        }

        if availableDirections.contains("northwest") {
            northwest?.draw(in: bounds)
        }

        if availableDirections.contains("southeast") {
            southeast?.draw(in: bounds)
        }

        if availableDirections.contains("southwest") {
            southwest?.draw(in: bounds)
        }

        if availableDirections.contains("up") {
            up?.draw(in: bounds)
        }

        if availableDirections.contains("down") {
            down?.draw(in: bounds)
        }

        if availableDirections.contains("out") {
            out?.draw(in: bounds)
        }
    }
}
