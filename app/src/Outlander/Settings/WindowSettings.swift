//
//  WindowSettings.swift
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
    public var visible: Int = 1
    public var timestamp: Int = 1
    public var showBorder: Int = 1
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
}

enum WindowLayoutCodingKeys: CodingKey {
    case version, primary, windows
}

struct WindowLayout: Codable {
    var version: Double = 2.0
    var primary: WindowData
    var windows: [WindowData]

    init(primary: WindowData, windows: [WindowData]) {
        self.primary = primary
        self.windows = windows
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: WindowLayoutCodingKeys.self)
        version = try container.decodeIfPresent(Double.self, forKey: .version) ?? 2.0
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
        let primary = createWindow("primary")
        let windows = [createWindow("main")]
        return WindowLayout(primary: primary, windows: windows)
    }

    static func createWindow(_ name: String) -> WindowData {
        let win = WindowData()
        win.name = name
        win.visible = 1
        win.x = 0
        win.y = 0
        win.height = 200
        win.width = 300
        return win
    }
}

class WindowLayoutLoader {
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
        guard var jsonData = try? decoder.decode(WindowLayout.self, from: data) else {
            return WindowLayout.defaults
        }

        jsonData.windows = jsonData.windows.sorted(by: { a, b -> Bool in
            a.order < b.order
        })

        return jsonData
    }

    func save(_ settings: ApplicationSettings, file: String, windows: WindowLayout) {
        let fileUrl = settings.paths.layout.appendingPathComponent(file)

        files.access {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
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
