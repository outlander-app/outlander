//
//  InMemoryFileSystem.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation
import Plugins

class InMemoryFileSystem: FileSystem {
    var contentToLoad: String?
    var savedContent: String?

    func contentsOf(_: URL) -> [URL] {
        fatalError()
    }

    func fileExists(_: URL) -> Bool {
        false
    }

    func load(_: URL) -> Data? {
        contentToLoad?.data(using: .utf8)
    }

    func append(_ data: String, to _: URL) throws {
        savedContent = data
    }

    func write(_ content: String, to _: URL) {
        savedContent = content
    }

    func write(_ data: Data, to _: URL) throws {
        savedContent = String(decoding: data, as: UTF8.self)
    }

    func foldersIn(directory _: URL) -> [URL] {
        []
    }

    func access(_ handler: @escaping () -> Void) {
        handler()
    }

    func ensure(folder _: URL) throws {}
}

struct TestEvent {
    var channel: String
    var data: Any?
    var text: TextData? {
        data as? TextData
    }
}

class InMemoryEvents: Events {
    public var history: [TestEvent] = []
    public var lastData: Any? {
        history.last?.data
    }

    func post(_ channel: String, data: Any?) {
        history.append(TestEvent(channel: channel, data: data))
    }

    func handle(_: AnyObject, channel _: String, handler _: @escaping (Any?) -> Void) {}

    func unregister(_: AnyObject) {}
}

class TestHost: IHost {
    var variables: [String: String] = [:]
    var sendHistory: [String] = []

    func send(text: String) {
        sendHistory.append(text)
    }

    func get(variable: String) -> String {
        variables[variable] ?? ""
    }

    func set(variable: String, value: String) {
        variables[variable] = value
    }

    func get(preset _: String) -> String? {
        nil
    }
}

class InMemoryPluginManager: OPlugin {
    var name: String {
        "Test Plugin Manager"
    }

    required init() {}

    func initialize(host _: IHost) {}

    func variableChanged(variable _: String, value _: String) {}

    func parse(input: String) -> String {
        input
    }

    func parse(xml: String) -> String {
        xml
    }

    func parse(text: String) -> String {
        text
    }

    func get(preset _: String) -> String? {
        nil
    }
}
