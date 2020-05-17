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
    func handle(_ target: AnyObject, channel:String, handler: @escaping (Any?)-> Void)
    func unregister(_ target: AnyObject)
}

extension Events {
    func echoText(_ text: String) {
        self.post("ol:text", data: "\(text)\n")
    }
    
    func echoError(_ text: String) {
        self.post("ol:error", data: "\(text)\n")
    }
}

class SwiftEventBusEvents : Events {
    
    public static var instance: Int = 0

    var id: Int = 0
    
    init() {
        SwiftEventBusEvents.instance += 1
        self.id = SwiftEventBusEvents.instance
    }

    func post(_ channel: String, data: Any?) {
        SwiftEventBus.post("\(self.id)_\(channel)", sender: data)
    }

    func handle(_ target: AnyObject, channel:String, handler: @escaping (Any?)-> Void) {
        SwiftEventBus.onMainThread(target, name: "\(self.id)_\(channel)") { notification in
            handler(notification?.object)
        }
    }

    func unregister(_ target: AnyObject) {
        SwiftEventBus.unregister(target)
    }
}
