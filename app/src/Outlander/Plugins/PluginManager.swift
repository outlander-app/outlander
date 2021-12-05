//
//  PluginManager.swift
//  Outlander
//
//  Created by Joe McBride on 12/4/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import Plugins

struct LocalPlugin {
    var bundle: Bundle?
    var value: OPlugin?
}

class PluginManager: OPlugin {
    private var host: IHost?
    private var files: FileSystem?
    private var context: GameContext?

    private var plugins: [LocalPlugin] = []

    var name: String {
        "Plugin Manager"
    }

    init(_ files: FileSystem, context: GameContext) {
        self.files = files
        self.context = context
    }

    required init() {}

    func add(_ plugin: OPlugin) {
        plugins.append(LocalPlugin(bundle: nil, value: plugin))
    }

    func initialize(host: IHost) {
        self.host = host

        for plugin in plugins {
            guard let p = plugin.value else {
                continue
            }
            host.send(text: "#echo Initializing Plugin '\(p.name)'")
            p.initialize(host: host)
        }
    }

    func variableChanged(variable: String, value: String) {
        for plugin in plugins {
            guard let p = plugin.value else {
                continue
            }
            p.variableChanged(variable: variable, value: value)
        }
    }

    func parse(input: String) -> String {
        var result = input
        for plugin in plugins {
            guard let p = plugin.value else {
                continue
            }
            result = p.parse(input: result)
        }
        return result
    }

    func parse(xml: String) -> String {
        var result = xml
        for plugin in plugins {
            guard let p = plugin.value else {
                continue
            }
            result = p.parse(xml: result)
        }
        return result
    }

    func parse(text: String) -> String {
        var result = text
        for plugin in plugins {
            guard let p = plugin.value else {
                continue
            }
            result = p.parse(text: result)
        }
        return result
    }

    func loadPlugins() {
        guard let files = files, let context = context else {
            return
        }

        let bundles = files.contentsOf(context.applicationSettings.paths.plugins).filter { $0.isFileURL && $0.lastPathComponent.hasSuffix(".bundle") }
        for b in bundles {
            if let bundle = Bundle(url: b), bundle.load() {
                if let pluginType = bundle.principalClass as? OPlugin.Type {
                    let instance = pluginType.init()
                    plugins.append(LocalPlugin(bundle: bundle, value: instance))
                }
            }
        }
    }
}
