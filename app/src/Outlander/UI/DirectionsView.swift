//
//  DirectionsView.swift
//  Outlander
//
//  Created by Joe McBride on 10/29/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    @discardableResult
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

class IndicatorView: NSView {
    var images: [String: NSImage] = [:]

    @IBInspectable var imageName: String = "bleeding" {
        didSet {
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
            images[imageName]?.draw(in: bounds)
        }
    }
}

class StandingIndicatorView: IndicatorView {
    @IBInspectable var isPlayerDead: Bool = false {
        didSet {
            needsDisplay = true
        }
    }

    override public func draw(_: NSRect) {
        if isPlayerDead {
            images["dead"]?.draw(in: bounds)
            return
        }

        images[imageName]?.draw(in: bounds)
    }
}

class DirectionsView: NSView {
    var images: [String: NSImage] = [:]

    var availableDirections: [String] = [] {
        didSet {
            needsDisplay = true
        }
    }

    override public var isFlipped: Bool {
        true
    }

    override public func draw(_: NSRect) {
        images["directions"]?.draw(in: bounds)

        if availableDirections.contains("north") {
            images["north"]?.draw(in: bounds)
        }

        if availableDirections.contains("south") {
            images["south"]?.draw(in: bounds)
        }

        if availableDirections.contains("east") {
            images["east"]?.draw(in: bounds)
        }

        if availableDirections.contains("west") {
            images["west"]?.draw(in: bounds)
        }

        if availableDirections.contains("northeast") {
            images["northeast"]?.draw(in: bounds)
        }

        if availableDirections.contains("northwest") {
            images["northwest"]?.draw(in: bounds)
        }

        if availableDirections.contains("southeast") {
            images["southeast"]?.draw(in: bounds)
        }

        if availableDirections.contains("southwest") {
            images["southwest"]?.draw(in: bounds)
        }

        if availableDirections.contains("up") {
            images["up"]?.draw(in: bounds)
        }

        if availableDirections.contains("down") {
            images["down"]?.draw(in: bounds)
        }

        if availableDirections.contains("out") {
            images["out"]?.draw(in: bounds)
        }
    }
}
