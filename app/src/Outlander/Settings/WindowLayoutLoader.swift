//
//  WindowLayoutLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 12/13/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

class WindowData: Codable {
    public var name: String = ""
    public var x: Double = 0
    public var y: Double = 0
    public var height: Double = 200
    public var width: Double = 200
    @NullEncodable public var title: String?
    @NullEncodable public var closedTarget: String?
    public var visible: Bool? = true
    public var timestamp: Bool? = false
    public var showBorder: Bool? = true
    public var fontName: String = "Helvetica"
    public var fontSize: Double = 14
    public var fontColor: String = "#d4d4d4"
    public var monoFontName: String = "Menlo"
    public var monoFontSize: Double = 13
    public var bufferSize: Int = 1000
    public var bufferClearSize: Int = 50
    public var backgroundColor: String = "#1e1e1e"
    public var borderColor: String = "#cccccc"
    public var order: Int = 0
    @NullEncodable public var padding: String? = "0,0"
    public var autoScroll: Bool?

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        x = try container.decodeIfPresent(Double.self, forKey: .x) ?? 0
        y = try container.decodeIfPresent(Double.self, forKey: .y) ?? 0
        height = try container.decodeIfPresent(Double.self, forKey: .height) ?? 0
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 0
        title = try container.decodeIfPresent(String.self, forKey: .title)
        closedTarget = try container.decodeIfPresent(String.self, forKey: .closedTarget)

        visible = try? container.decodeIfPresent(Bool.self, forKey: .visible)
        if visible == nil {
            let num = try? container.decodeIfPresent(Int.self, forKey: .visible) ?? 1
            visible = num == 1
        }
        if visible == nil { visible = true }

        timestamp = try? container.decodeIfPresent(Bool.self, forKey: .timestamp)
        if timestamp == nil {
            let num = try? container.decodeIfPresent(Int.self, forKey: .timestamp) ?? 1
            timestamp = num == 1
        }
        if timestamp == nil { timestamp = false }

        showBorder = try? container.decodeIfPresent(Bool.self, forKey: .showBorder)
        if showBorder == nil {
            let num = try? container.decodeIfPresent(Int.self, forKey: .showBorder) ?? 1
            showBorder = num == 1
        }
        if showBorder == nil { showBorder = true }

        fontName = try container.decodeIfPresent(String.self, forKey: .fontName) ?? "Helvetica"
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? 14
        fontColor = try container.decodeIfPresent(String.self, forKey: .fontColor) ?? "#d4d4d4"
        monoFontName = try container.decodeIfPresent(String.self, forKey: .monoFontName) ?? "Menlo"
        monoFontSize = try container.decodeIfPresent(Double.self, forKey: .monoFontSize) ?? 13

        bufferSize = try container.decodeIfPresent(Int.self, forKey: .bufferSize) ?? 1000
        bufferClearSize = try container.decodeIfPresent(Int.self, forKey: .bufferClearSize) ?? 50

        backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor) ?? "#1e1e1e"
        borderColor = try container.decodeIfPresent(String.self, forKey: .borderColor) ?? "#cccccc"

        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0

        padding = try container.decodeIfPresent(String.self, forKey: .padding) ?? "0,0"
        autoScroll = try container.decodeIfPresent(Bool.self, forKey: .autoScroll) ?? true
    }
}

enum WindowLayoutCodingKeys: CodingKey {
    case version, primary, windows
}

struct WindowLayout: Codable {
    var version: Double? = 2.0
    var primary: WindowData
    var windows: [WindowData]

    init(primary: WindowData, windows: [WindowData]) {
        self.primary = primary
        self.windows = windows
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: WindowLayoutCodingKeys.self)
        version = try? container.decodeIfPresent(Double.self, forKey: .version) ?? 2.0
        primary = try container.decodeIfPresent(WindowData.self, forKey: .primary) ?? WindowLayout.createWindow("primary")
        windows = try container.decodeIfPresent([WindowData].self, forKey: .windows) ?? [WindowLayout.createWindow("main")]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: WindowLayoutCodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(primary, forKey: .primary)
        try container.encode(windows, forKey: .windows)
    }

    static var defaults: WindowLayout {
        let primary = createWindow("primary", with: NSRect(x: 0, y: 55, width: 1440, height: 815))
        let windows = [
            createWindow("main", with: NSRect(x: 0, y: 260.4375, width: 1061, height: 424.5625)),
            createWindow("thoughts", with: NSRect(x: 0, y: 0, width: 521, height: 148), timestamp: true),
            createWindow("logons", with: NSRect(x: 1060, y: 0, width: 380, height: 133.86328125), timestamp: true),
            createWindow("death", with: NSRect(x: 1060, y: 133.359375, width: 380, height: 136), timestamp: true),
            createWindow("room", with: NSRect(x: 520.44140625, y: 0, width: 540.44140625, height: 260.99609375)),
            createWindow("percwindow", with: NSRect(x: 762.18359375, y: 203.68359375, width: 298.5234375, height: 158.07421875)),
            createWindow("log", with: NSRect(x: 0, y: 147, width: 521, height: 114), timestamp: true),
            createWindow("experience", with: NSRect(x: 1060.0625, y: 268.89453125, width: 379.9375, height: 416.10546875)),
            createWindow("assess", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false, closedTarget: "main"),
            createWindow("chatter", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false, closedTarget: "main"),
            createWindow("familiar", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false, closedTarget: "main"),
            createWindow("atmospherics", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false, closedTarget: "main"),
            createWindow("talk", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false, closedTarget: "conversation"),
            createWindow("whispers", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false, closedTarget: "conversation"),
            createWindow("conversation", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false, closedTarget: "log"),
            createWindow("ooc", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false, closedTarget: "conversation"),
            createWindow("group", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false, closedTarget: "conversation"),
            createWindow("inv", with: NSRect(x: 0, y: 0, width: 200, height: 200), visible: false),
            createWindow("raw", with: NSRect(x: 0, y: 0, width: 900, height: 400), visible: false),
            createWindow("shopwindow", with: NSRect(x: 0, y: 0, width: 900, height: 400), visible: false, closedTarget: "main"),
        ]
        return WindowLayout(primary: primary, windows: windows)
    }

    static func createWindow(_ name: String, with rect: NSRect = NSRect(x: 0, y: 0, width: 300, height: 200), visible: Bool = true, closedTarget: String = "", timestamp: Bool = false) -> WindowData {
        let win = WindowData()
        win.name = name
        win.visible = visible
        win.closedTarget = closedTarget
        win.timestamp = timestamp
        win.x = rect.origin.x
        win.y = rect.origin.y
        win.height = rect.height
        win.width = rect.width
        win.autoScroll = true
        return win
    }
}

class WindowLayoutLoader {
    let log = LogManager.getLog(String(describing: WindowLayoutLoader.self))

    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, file: String) -> WindowLayout? {
        let fileUrl = settings.paths.layout.appendingPathComponent(file)

        guard let data = files.load(fileUrl) else {
            return WindowLayout.defaults
        }

        let decoder = JSONDecoder()
        do {
            var jsonData = try decoder.decode(WindowLayout.self, from: data)
            jsonData.windows = jsonData.windows.sorted(by: { a, b -> Bool in
                a.order < b.order
            })

            return jsonData
        } catch {
            print("Error loading Window Layout:\n  \(error)")
            log.error("Error loading Window Layout:\n  \(error)")
            return WindowLayout.defaults
        }
    }

    func save(_ settings: ApplicationSettings, file: String, windows: WindowLayout) {
        let fileUrl = settings.paths.layout.appendingPathComponent(file)

        files.access {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            if let encodedData = try? encoder.encode(windows) {
                try? encodedData.write(to: fileUrl, options: .atomicWrite)
            }
        }
    }
}

@propertyWrapper
struct NullEncodable<T>: Codable where T: Codable {
    var wrappedValue: T?

    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard !container.decodeNil() else {
            wrappedValue = nil
            return
        }
        wrappedValue = try container.decode(T?.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch wrappedValue {
        case let .some(value): try container.encode(value)
        case .none: try container.encodeNil()
        }
    }
}
