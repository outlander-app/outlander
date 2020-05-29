//
//  WindowSettings.swift
//  Outlander
//
//  Created by Joseph McBride on 12/13/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

class WindowData: Decodable {
    public var name: String = ""
    public var x: Double = 0
    public var y: Double = 0
    public var height: Double = 200
    public var width: Double = 200
    public var title: String?
    public var closedTarget: String?
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

struct WindowLayout: Codable {
    var primary: WindowData
    var windows: [WindowData]

    init(primary: WindowData, windows: [WindowData]) {
        self.primary = primary
        self.windows = windows
    }

    func encode(to _: Encoder) throws {}
}

class WindowLayoutLoader {
    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ settings: ApplicationSettings, file: String) -> WindowLayout? {
        let fileUrl = settings.paths.layout.appendingPathComponent(file)

        guard let data = files.load(fileUrl) else {
            return nil
        }

        let decoder = JSONDecoder()
        guard var jsonData = try? decoder.decode(WindowLayout.self, from: data) else {
            return nil
        }

        jsonData.windows = jsonData.windows.sorted(by: { (a, b) -> Bool in
            a.order < b.order
        })

        return jsonData
    }

    func save(_ settings: ApplicationSettings, file: String, windows: WindowLayout) {
        let fileUrl = settings.paths.layout.appendingPathComponent(file)

        files.access {
            if let encodedData = try? JSONEncoder().encode(windows) {
                try? encodedData.write(to: fileUrl, options: .atomicWrite)
            }
        }
    }
}
