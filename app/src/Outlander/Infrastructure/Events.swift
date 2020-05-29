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
    func echoText(_ text: String) {
        post("ol:text", data: "\(text)\n")
    }

    func echoError(_ text: String) {
        post("ol:error", data: "\(text)\n")
    }

    func sendCommand(_ command: Command2) {
        post("ol:command", data: command)
    }
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
