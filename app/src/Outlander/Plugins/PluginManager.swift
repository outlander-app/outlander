//
//  PluginManager.swift
//  Outlander
//
//  Created by Joe McBride on 12/4/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class PluginManager: OPlugin {
    private var host: IHost?
    var plugins: [OPlugin] = []

    var name: String {
        "Plugin Manager"
    }

    func initialize(host: IHost) {
        self.host = host
        for plugin in plugins {
            host.send(text: "#echo Initializing Plugin '\(plugin.name)'")
            plugin.initialize(host: host)
        }
    }

    func variableChanged(variable: String, value: String) {
        for plugin in plugins {
            plugin.variableChanged(variable: variable, value: value)
        }
    }

    func parse(input: String) -> String {
        var result = input
        for plugin in plugins {
            result = plugin.parse(input: result)
        }
        return result
    }

    func parse(xml: String) -> String {
        var result = xml
        for plugin in plugins {
            result = plugin.parse(xml: result)
        }
        return result
    }

    func parse(text: String) -> String {
        var result = text
        for plugin in plugins {
            result = plugin.parse(text: result)
        }
        return result
    }
}
