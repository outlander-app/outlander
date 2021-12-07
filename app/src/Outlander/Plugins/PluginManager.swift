//
//  PluginManager.swift
//  Outlander
//
//  Created by Joe McBride on 12/4/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import Plugins

class LocalPlugin {
    var bundle: Bundle?
    var value: OPlugin?

    init(bundle: Bundle? = nil, value: OPlugin? = nil) {
        self.bundle = bundle
        self.value = value
    }

    func load() {
        guard let bundle = bundle else {
            return
        }
        if !bundle.isLoaded {
            bundle.load()
        }
        guard let pluginType = bundle.principalClass as? OPlugin.Type else {
            return
        }
        value = pluginType.init()
    }

    func unload() {
        value = nil
        // don't actually unload the bundle here, can cause memory issues
//        guard let bundle = bundle else {
//            return
//        }
//        if bundle.isLoaded {
//            bundle.unload()
//        }
    }
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

        context.events.handle(self, channel: "ol:plugin") { result in
            guard let (command, name) = result as? (String, String) else {
                return
            }

            DispatchQueue.main.async {
                switch command.lowercased() {
                case "load", "reload":
                    self.load(name)
                case "unload":
                    self.unload(name)
                default:
                    print("hrm")
                }
            }
        }
    }

    required init() {}

    func add(_ plugin: OPlugin) {
        plugins.append(LocalPlugin(value: plugin))
    }

    func unload(_ name: String) {
        // unload plugin if already loaded
        if let idx = plugins.firstIndex(where: { $0.bundle?.bundleURL.lastPathComponent == name }) {
            host?.send(text: "#echo Unloading plugin \(name)")
            let plugin = plugins[idx]
            plugin.unload()
            plugins.remove(at: idx)
        }
    }

    func load(_ name: String) {
        unload(name)

        guard let files = files, let context = context else {
            return
        }

        do {
            try ObjC.perform {
                let bundleUrl = files.contentsOf(context.applicationSettings.paths.plugins).first { $0.isFileURL && $0.lastPathComponent.hasSuffix(".bundle") }
                if bundleUrl != nil {
                    load(url: bundleUrl!)
                }
            }
        } catch {
            context.events.echoError("Error when trying to load plugin \(name):\n\(error)")
        }
    }

    func load(url: URL) {
        guard let bundle = Bundle(url: url), bundle.load() == true else {
            return
        }

//        print("loaded? \(bundle.isLoaded)")

        do {
            try ObjC.perform {
                if let pluginType = bundle.principalClass as? OPlugin.Type {
                    let instance = pluginType.init()
                    plugins.append(LocalPlugin(bundle: bundle, value: instance))

                    if host != nil {
                        host!.send(text: "#echo Initializing Plugin '\(instance.name)'")
                        instance.initialize(host: host!)
                    }
                }
            }
        } catch {
            context?.events.echoError("Error when trying to load plugin \(url):\n\(error)")
        }
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
        for url in bundles {
            load(url: url)
        }
    }
}
