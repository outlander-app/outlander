//
//  WindowCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 5/1/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

protocol Events {
    func post(_ channel: String, data: Any?)
    func handle(_ target: AnyObject, channel:String, handler: @escaping (Any?)-> Void)
    func unregister(_ target: AnyObject)
}

class SwiftEventBusEvents : Events {
    func post(_ channel: String, data: Any?) {
        SwiftEventBus.post(channel, sender: data)
    }

    func handle(_ target: AnyObject, channel:String, handler: @escaping (Any?)-> Void) {
        SwiftEventBus.onMainThread(target, name: channel) { notification in
            handler(notification?.object)
        }
    }

    func unregister(_ target: AnyObject) {
        SwiftEventBus.unregister(target)
    }
}

class WindowCommandHandler : ICommandHandler {

    let command = "#window"

    let validCommands = ["add", "clear", "hide", "list", "reload", "show"]

    func handle(command: String, withContext: GameContext) {
        let commands = command[7...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)

        if commands.hasPrefix("reload") {
            let loader = WindowLayoutLoader()
            if let layout = loader.load(withContext.applicationSettings, file: "default.cfg") {
                withContext.layout = layout
                withContext.events.post("ol:window", data: ["action":"reload", "window":""])
            }
            return
        }

        guard let matches = try? Regex("^(\\w+)(\\s(\\w+))?$").matches2(commands) else {
            return
        }

        let action = matches.valueAt(index: 1) ?? ""
        let window = matches.valueAt(index: 3) ?? ""
        
        if validCommands.contains(action) {
            withContext.events.post("ol:window", data: ["action":action, "window":window])
        }
    }
}
