//
//  WindowSettings.swift
//  Outlander
//
//  Created by Joseph McBride on 12/13/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

class ApplicationPaths {

    init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        rootUrl = paths[0]
    }

    var rootUrl: URL

    var config: URL {
        get {
            return rootUrl.appendingPathComponent("Config")
        }
    }

    var profiles: URL {
        get {
            return config.appendingPathComponent("Profiles")
        }
    }

    var layout: URL {
        get {
            return config.appendingPathComponent("Layout")
        }
    }

    var maps: URL {
        get {
            return rootUrl.appendingPathComponent("Maps")
        }
    }

    var logs: URL {
        get {
            return rootUrl.appendingPathComponent("Logs")
        }
    }
}

class ApplicationSettings {
    var paths:ApplicationPaths = ApplicationPaths()
}

class WindowData : Decodable {
    public var name: String = ""
    public var x:Double = 0
    public var y:Double = 0
    public var height:Double = 200
    public var width:Double = 200
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

class WindowLayout : Decodable {
    var primary: WindowData
    var windows: [WindowData]

    init(primary: WindowData, windows: [WindowData]) {
        self.primary = primary
        self.windows = windows
    }
}

class WindowLayoutLoader {
    func load(_ settings:ApplicationSettings, file:String) -> WindowLayout? {

        let fileUrl = settings.paths.layout.appendingPathComponent(file)
        
        if !fileUrl.startAccessingSecurityScopedResource() {
            print("startAccessingSecurityScopedResource returned false. This directory might not need it, or this URL might not be a security scoped URL, or maybe something's wrong?")
        }

        guard let data = try? Data(contentsOf: fileUrl) else {
            fileUrl.stopAccessingSecurityScopedResource()
            return nil
        }

        fileUrl.stopAccessingSecurityScopedResource()
        
        let decoder = JSONDecoder()
//        guard let jsonData = try? decoder.decode(WindowLayout.self, from: data) else {
//            return nil
//        }

        let jsonData = try! decoder.decode(WindowLayout.self, from: data)
        
        jsonData.windows = jsonData.windows.sorted(by: { (a, b) -> Bool in
            return a.order < b.order
        })

        return jsonData
    }
}
