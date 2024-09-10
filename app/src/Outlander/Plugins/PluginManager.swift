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
        guard let bundle else {
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

struct PluginEvent: Event {
    var command: String
    var name: String
}

class PluginManager: OPlugin {
    private var host: IHost?
    private var files: FileSystem?
    private var context: GameContext?

    private var plugins: [LocalPlugin] = []

    var name: String {
        "Plugin Manager"
    }

    init(_ files: FileSystem, context: GameContext, host: IHost) {
        self.host = host
        self.files = files
        self.context = context

        context.events2.register(self) { (evt: PluginEvent) in
            DispatchQueue.main.async {
                switch evt.command.lowercased() {
                case "load", "reload":
                    self.load(evt.name)
                case "unload":
                    self.unload(evt.name)
                default:
                    print("hrm")
                }
            }
        }
    }

    required init() {}

    deinit {
        context?.events2.unregister(self, DummyEvent<PluginEvent>())
    }

    func add(_ plugin: OPlugin) {
        plugins.append(LocalPlugin(value: plugin))
    }

    func unload(_ name: String) {
        // unload plugin if already loaded
        if let idx = plugins.firstIndex(where: { $0.bundle?.bundleURL.lastPathComponent.lowercased() == name.lowercased() }) {
            host?.send(text: "#echo Unloading plugin \(name)")
            let plugin = plugins[idx]
            plugin.unload()
            plugins.remove(at: idx)
        }
    }

    func load(_ name: String) {
        unload(name)

        guard let files, let context else {
            return
        }

        do {
            try ObjC.perform {
                let bundleUrl = files.contentsOf(context.applicationSettings.paths.plugins).first { $0.isFileURL && $0.lastPathComponent.lowercased() == name.lowercased() }
                if bundleUrl != nil {
                    load(url: bundleUrl!)
                }
            }
        } catch {
            context.events2.echoError("Error when trying to load plugin \(name):\n\(error)")
        }
    }

    func load(url: URL) {
        files?.access {
            guard let bundle = Bundle(url: url) else {
                self.host?.send(text: "#echo Unable to load bundle '\(url)'")
                print("#echo Unable to load bundle '\(url)'")
                return
            }

            guard bundle.load() == true else {
                self.host?.send(text: "#echo Unable to load bundle '\(url)'")
                print("#echo Unable to load bundle '\(url)'")
                return
            }

            //        print("loaded? \(bundle.isLoaded)")

            do {
                try ObjC.perform {
                    if let pluginType = bundle.principalClass as? OPlugin.Type {
                        let instance = pluginType.init()
                        self.plugins.append(LocalPlugin(bundle: bundle, value: instance))

                        guard let host = self.host else {
                            return
                        }

                        host.send(text: "#echo Initializing Plugin '\(instance.name)'")
                        instance.initialize(host: host)
                    }
                }
            } catch {
                self.context?.events2.echoError("Error when trying to load plugin \(url):\n\(error)")
            }
        }
    }

    func initialize(host: IHost) {
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

    func parse(text: String, window: String) -> String {
        var result = text
        for plugin in plugins {
            guard let p = plugin.value else {
                continue
            }
            result = p.parse(text: result, window: window)
        }
        return result
    }

    func loadPlugins() {
        guard let files, let context else {
            return
        }

        let bundles = files.contentsOf(context.applicationSettings.paths.plugins).filter { $0.isFileURL && $0.lastPathComponent.hasSuffix(".bundle") }
        for url in bundles {
            load(url: url)
        }
    }
}
