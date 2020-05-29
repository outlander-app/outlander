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

    func fileExists(_: URL) -> Bool {
        fatalError()
    }

    func load(_: URL) -> Data? {
        return contentToLoad?.data(using: .utf8)
    }

    func write(_ content: String, to _: URL) {
        savedContent = content
    }

    func access(_ handler: @escaping () -> Void) {
        handler()
    }
}

class InMemoryEvents: Events {
    public var lastData: Any?

    func post(_: String, data: Any?) {
        lastData = data
    }

    func handle(_: AnyObject, channel _: String, handler _: @escaping (Any?) -> Void) {}

    func unregister(_: AnyObject) {}
}
