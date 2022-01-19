//
//  MapWindow.swift
//  Outlander
//
//  Created by Joe McBride on 1/31/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

class MapsDataSource: NSObject, NSComboBoxDataSource {
    public typealias Count = () -> Int
    public typealias Description = (_ index: Int) -> String
    public typealias Values = () -> [MapZone]

    var getCount: Count = { 0 }
    var getDescription: Description = { _ in "" }
    var getValues: Values = { [] }

    func indexOfMap(id: String) -> Int? {
        let values = getValues()

        for (index, item) in values.enumerated() {
            if item.id == id {
                return index
            }
        }

        return nil
    }

    func mapAt(index: Int) -> MapZone? {
        let values = getValues()

        guard index > 0, index < values.count else {
            return nil
        }

        for (idx, item) in values.enumerated() {
            if idx == index {
                return item
            }
        }

        return nil
    }

    func numberOfItems(in _: NSComboBox) -> Int {
        getCount()
    }

    func comboBox(_: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index > -1 else {
            return ""
        }

        return getDescription(index)
    }
}

class MapWindow: NSWindowController, NSComboBoxDelegate {
    @IBOutlet var mapView: MapView?
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var roomLabel: NSTextField!
    @IBOutlet var zoneLabel: NSTextField!
    @IBOutlet var mapLevelSegment: NSSegmentedControl!
    @IBOutlet var mapsList: NSComboBox!

    private var appearanceObserver: NSKeyValueObservation?

    var shouldCenterOnRoom = true
    var dataSource = MapsDataSource()

    var loaded: Bool = false

    var context: GameContext?

    var mapLevel: Int = 0 {
        didSet {
            updateLevel()
        }
    }

    private func updateLevel() {
        guard loaded else { return }
        mapView?.mapLevel = mapLevel
        mapLevelSegment.setLabel("Level \(mapLevel)", forSegment: 1)
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
        self.context?.events.handle(self, channel: "ol:mapper:setpath") { result in
            if let path = result as? [String] {
                DispatchQueue.main.async {
                    self.setWalkPath(path)
                }
            }
        }

        self.context?.events.handle(self, channel: "ol:variable:changed") { result in
            if let dict = result as? [String: String] {
                for (key, value) in dict {
                    if key == "zoneid" {
                        guard self.loaded else { return }
                        self.setSelectedZone()
                    }

                    if key == "roomid" {
                        self.mapView?.currentRoomId = value
                        
                        if let zoneId = self.context?.globalVars["zoneid"], let zone = self.context?.maps[zoneId] {
                            let room = self.context?.findCurrentRoom(zone)
                            self.mapLevel = room?.position.z ?? 0
                        }

                        if self.shouldCenterOnRoom {
                            self.scrollToRoom()
                        }
                    }
                }
            }
        }

        dataSource.getCount = {
            self.context?.maps.count ?? 0
        }

        dataSource.getValues = {
            guard let maps = self.context?.maps else {
                return []
            }
            let values = Array(maps.values).sorted { $0.id.compare($1.id, options: .numeric) == .orderedAscending }
            return values
        }

        dataSource.getDescription = { index in
            let values = self.dataSource.getValues()

            guard index > -1, index < values.count else {
                return ""
            }

            let map = values[index]
            return "\(map.id). \(map.name)"
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        mapsList?.dataSource = dataSource

        if window?.contentView?.isDarkMode == false {
            mapView?.theme = MapTheme.light
        }

        appearanceObserver = window?.contentView?.observe(\.effectiveAppearance) { [weak self] _, _ in
//            print("map view: \(self?.window?.contentView?.isDarkMode), \(self?.window?.contentView?.effectiveAppearance.name)")
            var theme = MapTheme.dark

            if self?.window?.contentView?.isDarkMode == false {
                theme = .light
            }

            self?.mapView?.theme = theme
        }

        loaded = true

        roomLabel.stringValue = ""
        zoneLabel.stringValue = ""
        updateLevel()

        mapView?.nodeTravelTo = { node in
            self.context?.events.echoText("#goto \(node.id) (\(node.name))", preset: "automapper")
            self.context?.events.sendCommand(Command2(command: "#goto \(node.id)", isSystemCommand: true))
        }

        mapView?.nodeClicked = { node in
            if node.isTransfer() {
                self.context?.events.echoText("Switching to map \(node.id), \(node.name)", preset: "automapper")

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
        print("MapWindow - selecting zone ...")
        guard let zoneId = context?.globalVars["zoneid"], let zone = context?.maps[zoneId] else { return }

        if let idx = dataSource.indexOfMap(id: zoneId) {
            mapsList.selectItem(at: idx)
        }

        renderMap(zone)
        scrollToRoom()
    }

    func renderMap(_ zone: MapZone) {
        print("rendering map ... \(zone.id)")
        let rect = zone.mapSize(0, padding: 100.0)

        if let context = context {
            let room = context.findCurrentRoom(zone)
            mapLevel = room?.position.z ?? 0
            mapView?.currentRoomId = room?.id ?? ""
        }

        mapView?.setFrameSize(rect.size)
        mapView?.setZone(zone, rect: rect)
        clearWalkPath()

        zoneLabel.stringValue = "\(zone.rooms.count) rooms"
    }

    func setWalkPath(_ path: [String]) {
        mapView?.walkPath = path
    }

    func clearWalkPath() {
        mapView?.walkPath = []
    }

    func comboBoxSelectionDidChange(_: Notification) {
        print("Selection changed")
        guard let idx = mapsList?.indexOfSelectedItem else {
            return
        }
        guard let selectedMap = dataSource.mapAt(index: idx) else {
            return
        }

        print("Selection changed \(idx) \(selectedMap.id) \(selectedMap.name)")

        context?.mapZone = selectedMap
    }

    @IBAction func centerAction(_ sender: Any) {
        shouldCenterOnRoom = !shouldCenterOnRoom

        if let btn = sender as? NSButton {
            btn.state = shouldCenterOnRoom ? .on : .off
        }

        if shouldCenterOnRoom {
            scrollToRoom()
        }
    }

    func scrollToRoom() {
        guard let roomId = context?.globalVars["roomid"] else {
            return
        }

        guard let rect = mapView?.rectForRoom(roomId) else {
            return
        }

        let xpadding: CGFloat = scrollView.contentSize.width / 4
        let ypadding: CGFloat = scrollView.contentSize.height / 2

        let point = NSPoint(x: rect.origin.x - xpadding, y: rect.origin.y - ypadding)
        scrollView.contentView.scroll(point)

        print("Content size: \(scrollView.contentSize), point: \(point)")
    }
}
