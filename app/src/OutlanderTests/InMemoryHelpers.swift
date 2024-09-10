//
//  InMemoryHelpers.swift
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

class InMemoryEvents: Events2 {
    public var history: [BaseEvent] = []
    public var lastData: BaseEvent? {
        history.last
    }

    public var processor: CommandProcesssor?
    public var gameContext: GameContext?

    func post(_ event: some Event) {
        guard !(event is VariableChangedEvent) else {
            return
        }

        if let cmd = event as? CommandEvent {
            processor?.process(cmd.command, with: gameContext!)
            return
        }

        history.append(event)
    }

    func register<EventType>(_: AnyObject, handler _: @escaping ((EventType) -> Void)) where EventType: Event {}

    func post(_ event: some StickyEvent) {
        guard !(event is VariableChangedEvent) else {
            return
        }

        history.append(event)
    }

    func register<EventType>(_: AnyObject, handler _: @escaping ((_ event: EventType) -> Void)) where EventType: StickyEvent {}

    func unregister(_: AnyObject, _: DummyEvent<some BaseEvent>) {}
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

    func write(content _: String, to _: String) {}

    func append(content _: String, to _: String) {}

    func load(from _: String) -> String? {
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

    func parse(text: String, window _: String) -> String {
        text
    }

    func get(preset _: String) -> String? {
        nil
    }
}

class InMemoryLogger: ILogger {
    var name: String = "InMemory"
    var history: [String] = []

    func info(_ message: String) {
        append("INFO", message)
    }

    func warn(_ message: String) {
        append("WARN", message)
    }

    func error(_ message: String) {
        append("ERROR", message)
    }

    func stream(_ data: String) {
        append("STREAM", data)
    }

    func rawStream(_ data: String) {
        append("RAWSTREAM", data)
    }

    func scriptLog(_ data: String, to: String) {
        append("SCRIPT(\(to))", data)
    }

    func append(_ category: String, _ message: String) {
        history.append("[\(category)]: \(message)")
    }
}
