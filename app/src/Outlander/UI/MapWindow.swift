//
//  MapWindow.swift
//  Outlander
//
//  Created by Joe McBride on 1/31/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

class MapWindow: NSWindowController {
    @IBOutlet var mapView: MapView?
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var roomLabel: NSTextField!
    @IBOutlet var zoneLabel: NSTextField!
    @IBOutlet var mapLevelSegment: NSSegmentedControl!

    var loaded: Bool = false

    var context: GameContext?

    var mapLevel: Int = 0 {
        didSet {
            mapView?.mapLevel = mapLevel
            mapLevelSegment.setLabel("Level \(mapLevel)", forSegment: 1)
        }
    }

    var mapZoom: CGFloat = 1.0 {
        didSet {
            if self.mapZoom == 0 {
                self.mapZoom = 0.5
            }
        }
    }

    override var windowNibName: String! {
        "MapWindow"
    }

    func initialize(context: GameContext) {
        self.context = context
        self.context?.events.handle(self, channel: "ol:variable:changed") { result in
            if let dict = result as? [String: String] {
                for (key, value) in dict {
                    if key == "zoneid" {
                        guard self.loaded else { return }
                        guard let newMap = context.mapZone else { return }
                        self.renderMap(newMap)
                    }

                    if key == "roomid" {
                        self.mapView?.currentRoomId = value
                    }
                }
            }
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        loaded = true

        roomLabel.stringValue = ""
        zoneLabel.stringValue = ""

        mapView?.nodeTravelTo = { node in
            self.context?.events.echoText("#goto \(node.id) (\(node.name))", preset: "scriptinput")
            self.context?.events.sendCommand(Command2(command: "#goto \(node.id)", isSystemCommand: true))
        }

        mapView?.nodeClicked = { node in
            if node.isTransfer() {
                self.context?.events.echoText("switch map \(node.id) (\(node.name))", preset: "scriptinput")
//                self.context?.globalVars["roomid"] = node.id

                guard let transferMap = node.transferMap else {
                    return
                }
                guard let newMap = self.context?.mapForFile(file: transferMap) else {
                    return
                }

                self.context?.mapZone = newMap
            }
        }

        mapView?.nodeHover = { node in
            guard let room = node else {
                self.roomLabel.stringValue = ""
                return
            }

            var notes = ""
            if room.notes != nil {
                notes = "(\(room.notes!))"
            }
            self.roomLabel.stringValue = "#\(room.id) - \(room.name) \(notes)"
        }
    }

    @IBAction func levelAction(_ sender: Any) {
        guard let ctrl = sender as? NSSegmentedControl else { return }
        let segment = ctrl.selectedSegment

        if segment == 0 {
            mapLevel += 1
        } else {
            mapLevel -= 1
        }

        ctrl.setLabel("Level \(mapLevel)", forSegment: 1)
    }

    @IBAction func zoomAction(_ sender: Any) {
        guard let ctrl = sender as? NSSegmentedControl else { return }
        let segment = ctrl.selectedSegment

        if segment == 0 {
            mapZoom += 0.5
        } else {
            mapZoom -= 0.5
        }

        let clipView = scrollView.contentView
        var clipViewBounds = clipView.bounds
        let clipViewSize = clipView.frame.size

        clipViewBounds.size.width = clipViewSize.width / mapZoom
        clipViewBounds.size.height = clipViewSize.height / mapZoom

        clipView.setBoundsSize(clipViewBounds.size)
    }

    func setSelectedZone() {
        guard let zone = context?.mapZone else { return }

        renderMap(zone)
    }

    func renderMap(_ zone: MapZone) {
        let rect = zone.mapSize(0, padding: 100.0)

        if let context = context {
            let room = context.findCurrentRoom(zone)
            mapLevel = room?.position.z ?? 0
            mapView?.currentRoomId = room?.id ?? ""
        }

        mapView?.setFrameSize(rect.size)
        mapView?.setZone(zone, rect: rect)
        clearWalkPath()

        zoneLabel.stringValue = "Map \(zone.id). \(zone.name), \(zone.rooms.count) rooms"
    }

    func setWalkPath(_ path: [String]) {
        mapView?.walkPath = path
    }

    func clearWalkPath() {
        mapView?.walkPath = []
    }
}
