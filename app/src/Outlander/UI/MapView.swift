//
//  MapView.swift
//  Outlander
//
//  Created by Joe McBride on 1/31/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

class KnownColors {
    static var colors: [String: String] = [
        // Ranik-Based Colors
        "Lime": "#00ff00", // other room of economic interest (bank teller, exchange, loot buyers, services, etc.)
        "Red": "#ff3300", // room where you can purchase an item
        "Yellow": "#ffff00", // stat training room
        "Fuchsia": "#ff00cc", // throughpoint, portal, or transport
        "Aqua": "#00ffff", // PC housing
        "Blue": "#0000ff", // water room (swimming required)
        "Navy": "#000080", // underwater room (drowning possible)
        "Sienna": "#993300", // mining room

        // Additional Colors
        "Sand": "#C2B280", // ranger trail
        "Orange": "#FF8000", // guildleader
        "Amber": "#FFBF00", // roundtime or other non-swimming obstacle
        "Olive": "#808000", // Kraelyst travel script start point
        "Green": "#008000", // lumber room
        "Mint": "#00BF80", // auto-healer
        "Periwinkle": "#A6A3D9", // pilgrim badge shrine
        "Eggplant": "#400040", // depart room
        "Purple": "#800080", // favor altar
    ]

    static func find(_ color: String?) -> NSColor? {
        guard let color = color else { return nil }
        guard let hex = colors[color] else {
            return nil
        }

        return NSColor(hex: hex)
    }
}

struct MapTheme {
    var text: String
    var currentRoom: String
    var room: String
    var roomBorder: String
    var path: String
    var zoneExit: String
    var zoneExitBorder: String

    static var dark: MapTheme {
        // purple alt
        // #382b4e
        // #5e4983

        // blue
        // zoneExit: "#111e2f", zoneExitBorder: "#224a82")

        // purple
        // zoneExit: "#1f1e30", zoneExitBorder: "#9367e0")

        MapTheme(text: "#d9d9d9", currentRoom: "#990099", room: "#d9d9d9", roomBorder: "#000000", path: "#d9d9d9", zoneExit: "#1f1e30", zoneExitBorder: "#9367e0")
    }

    static var light: MapTheme {
        MapTheme(text: "#000000", currentRoom: "#990099", room: "#ffffff", roomBorder: "#000000", path: "#000000", zoneExit: "#ffffff", zoneExitBorder: "#272ad8")
    }
}

extension String {
    func asColor() -> NSColor? {
        NSColor(hex: self)
    }
}

extension MapPosition {
    func translatePosition(rect: NSRect) -> CGPoint {
        let centerX = rect.origin.x
        let centerY = rect.origin.y

        let resX = CGFloat(x) + centerX
        let resY = CGFloat(y) + centerY

        return CGPoint(x: resX, y: resY)
    }
}

class MapView: NSView {
    var rect: NSRect?
    var roomSize: CGFloat = 7.0
    var nodeLookup: [NSValue: String] = [:]
    var lastMousePosition: CGPoint?
    var trackingArea: NSTrackingArea?

    var nodeHover: ((MapNode?) -> Void)?
    var nodeClicked: ((MapNode) -> Void)?
    var nodeTravelTo: ((MapNode) -> Void)?

    var mapZone: MapZone?

    var mapLevel: Int = 0 {
        didSet {
            if oldValue != mapLevel {
                nodeLookup = [:]
                needsDisplay = true
            }
        }
    }

    var currentRoomId: String? = "" {
        didSet {
            if oldValue != currentRoomId {
                redrawRoom(oldValue)
                redrawRoom(currentRoomId)
            }
        }
    }

    func setZone(_ mapZone: MapZone, rect: NSRect) {
        self.mapZone = mapZone
        self.rect = rect
        nodeLookup = [:]

        updateTrackingAreas()
        needsDisplay = true
    }

    var debounceTimer: Timer?

    func debouceLookupRoom() {
        if let timer = debounceTimer {
            timer.invalidate()
        }

        debounceTimer = Timer(timeInterval: 0.07, target: self, selector: #selector(MapView.lookupRoom), userInfo: nil, repeats: false)
        RunLoop.current.add(debounceTimer!, forMode: RunLoop.Mode.default)
    }

    @objc func lookupRoom() {
        DispatchQueue.main.async {
            let room = self.lookupRoomFromPoint(self.lastMousePosition)
            self.nodeHover?(room)

            if let room = room, room.isTransfer() {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }

    func lookupRoomFromPoint(_ maybePoint: CGPoint?) -> MapNode? {
        guard let point = maybePoint else {
            return nil
        }

        for (key, id) in nodeLookup {
            if key.rectValue.contains(point) {
                return mapZone?.room(id: id)
            }
        }

        return nil
    }

    override var isFlipped: Bool {
        true
    }

    func redrawRoom(_ id: String?) {
        if let rect = rectForRoom(id) {
            DispatchQueue.main.async {
                self.setNeedsDisplay(rect)
            }
        }
    }

    func rectForRoom(_ id: String?) -> NSRect? {
        guard let roomId = id else {
            return nil
        }
        guard let room = mapZone?.room(id: roomId) else {
            return nil
        }
        guard let rect = self.rect else {
            return nil
        }

        let point = room.position.translatePosition(rect: rect)

        let outlineRect = NSMakeRect(point.x - (roomSize / 2), point.y - (roomSize / 2), roomSize, roomSize)
        return outlineRect
    }

    override func updateTrackingAreas() {
        if trackingArea != nil {
            removeTrackingArea(trackingArea!)
        }

        trackingArea = createTrackingArea()
        addTrackingArea(trackingArea!)

        super.updateTrackingAreas()
    }

    func createTrackingArea() -> NSTrackingArea {
        NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved],
            owner: self,
            userInfo: nil
        )
    }

    override func mouseMoved(with _: NSEvent) {
        let globalLocation = NSEvent.mouseLocation
        let windowLocation = window!.convertFromScreen(NSRect(x: globalLocation.x, y: globalLocation.y, width: 0, height: 0))
        let viewLocation = convert(windowLocation.origin, from: nil)

        lastMousePosition = viewLocation

        debouceLookupRoom()
    }

    override func mouseUp(with _: NSEvent) {
        let globalLocation = NSEvent.mouseLocation
        let windowLocation = window!.convertFromScreen(NSRect(x: globalLocation.x, y: globalLocation.y, width: 0, height: 0))
        let viewLocation = convert(windowLocation.origin, from: nil)

        if let room = lookupRoomFromPoint(viewLocation) {
            nodeClicked?(room)
        }
    }

    override func rightMouseUp(with _: NSEvent) {
        let globalLocation = NSEvent.mouseLocation
        let windowLocation = window!.convertFromScreen(NSRect(x: globalLocation.x, y: globalLocation.y, width: 0, height: 0))
        let viewLocation = convert(windowLocation.origin, from: nil)

        if let room = lookupRoomFromPoint(viewLocation) {
            nodeTravelTo?(room)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let zone = mapZone else {
            return
        }

        guard let rect = self.rect else {
            return
        }

        let theme = MapTheme.dark

        var strokeWidth: CGFloat = 0.5
        NSBezierPath.defaultLineCapStyle = .round
        NSBezierPath.defaultLineWidth = strokeWidth

        let rooms = zone.rooms.filter { $0.position.z == self.mapLevel }

        // draw room connections
        for room in rooms {
            let point = room.position.translatePosition(rect: rect)

            theme.path.asColor()?.setStroke()

            let hasDest = room.arcs.filter { $0.destination.count > 0 && !$0.hidden }

            for dest in hasDest {
                let arc = zone.room(id: dest.destination)!
                let arcPoint = arc.position.translatePosition(rect: rect)

                NSBezierPath.strokeLine(from: point, to: arcPoint)
            }
        }

        // draw room boxes
        for room in rooms {
            theme.room.asColor()?.setFill()

            if room.isTransfer() {
                strokeWidth = 1.0
                theme.zoneExitBorder.asColor()?.setStroke()
                theme.zoneExit.asColor()?.setFill()
            } else {
                strokeWidth = 0.5
                theme.roomBorder.asColor()?.setStroke()
            }

            let point = room.position.translatePosition(rect: rect)
            let outlineRect = NSMakeRect(point.x - (roomSize / 2), point.y - (roomSize / 2), roomSize, roomSize)

            let loc = NSValue(rect: outlineRect)
            nodeLookup[loc] = room.id

            let border = NSBezierPath()
            border.lineWidth = strokeWidth
            border.appendRect(outlineRect)
            border.lineCapStyle = .round
            border.stroke()

            if room.id == currentRoomId {
                theme.currentRoom.asColor()?.setFill()

            } else if room.color != nil && room.color!.hasPrefix("#") {
                NSColor(hex: room.color!)?.setFill()

            } else if let color = KnownColors.find(room.color) {
                color.setFill()
            }

            NSMakeRect(
                outlineRect.origin.x + (strokeWidth / 2.0),
                outlineRect.origin.y + (strokeWidth / 2.0),
                outlineRect.width - (strokeWidth / 2.0 * 2.0),
                outlineRect.height - (strokeWidth / 2.0 * 2.0)
            ).fill()
        }

        let labels = zone.labels.filter { $0.position.z == self.mapLevel }
        for label in labels {
            let point = label.position.translatePosition(rect: rect)
            let storage = NSTextStorage(string: label.text)
            storage.foregroundColor = theme.text.asColor()
            storage.draw(at: point)
        }

        super.draw(dirtyRect)
    }
}
