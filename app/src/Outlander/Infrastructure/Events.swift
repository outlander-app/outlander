//
//  Events.swift
//  Outlander
//
//  Created by Joseph McBride on 5/16/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

protocol Events {
    func post(_ channel: String, data: Any?)
    func handle(_ target: AnyObject, channel: String, handler: @escaping (Any?) -> Void)
    func unregister(_ target: AnyObject)
}

extension Events {
    func echoText(_ text: String, preset: String? = nil, color: String? = nil, mono: Bool = false) {
        let data = TextData(text: "\(text)\n", preset: preset, color: color, mono: mono)
        post("ol:text", data: data)
    }

    func echoError(_ text: String) {
        post("ol:error", data: "\(text)\n")
    }

    func sendCommand(_ command: Command2) {
        post("ol:command", data: command)
    }

    func variableChanged(_ key: String, value: String) {
        // print("var changed: \(key): \(value)")
        post("ol:variable:changed", data: [key: value])
    }
}

struct TextData {
    var text: String
    var preset: String?
    var color: String?
    var mono: Bool = false
}

class NulloEvents: Events {
    func post(_: String, data _: Any?) {}

    func handle(_: AnyObject, channel _: String, handler _: @escaping (Any?) -> Void) {}

    func unregister(_: AnyObject) {}
}

class SwiftEventBusEvents: Events {
    public static var instance: Int = 0

    let id: Int

    init() {
        SwiftEventBusEvents.instance += 1
        id = SwiftEventBusEvents.instance
    }

    func post(_ channel: String, data: Any?) {
        SwiftEventBus.post("\(id)_\(channel)", sender: data)
    }

    func handle(_ target: AnyObject, channel: String, handler: @escaping (Any?) -> Void) {
        SwiftEventBus.onMainThread(target, name: "\(id)_\(channel)") { notification in
            handler(notification?.object)
        }
    }

    func unregister(_ target: AnyObject) {
        SwiftEventBus.unregister(target)
    }
}
