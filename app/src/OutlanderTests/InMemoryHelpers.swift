//
//  InMemoryFileSystem.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class InMemoryFileSystem: FileSystem {
    var contentToLoad: String?
    var savedContent: String?

    func contentsOf(_: URL) -> [URL] {
        fatalError()
    }

    func fileExists(_: URL) -> Bool {
        fatalError()
    }

    func load(_: URL) -> Data? {
        contentToLoad?.data(using: .utf8)
    }

    func write(_ content: String, to _: URL) {
        savedContent = content
    }

    func write(_ data: Data, to _: URL) throws {
        savedContent = String(decoding: data, as: UTF8.self)
    }

    func access(_ handler: @escaping () -> Void) {
        handler()
    }
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
