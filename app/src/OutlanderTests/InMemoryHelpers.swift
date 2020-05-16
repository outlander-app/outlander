//
//  InMemoryFileSystem.swift
//  OutlanderTests
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class InMemoryFileSystem : FileSystem {
    
    var contentToLoad:String?
    var savedContent:String?
    
    func load(_ file: URL) -> Data? {
        return contentToLoad?.data(using: .utf8)
    }

    func write(_ content: String, to fileUrl: URL) {
        self.savedContent = content
    }
    
    func access(_ handler: @escaping ()->Void) {
        handler()
    }
}

class InMemoryEvents : Events {
    public var lastData: Any?
    
    func post(_ channel: String, data: Any?) {
        self.lastData = data
    }
    
    func handle(_ target: AnyObject, channel: String, handler: @escaping (Any?) -> Void) {
    }
    
    func unregister(_ target: AnyObject) {
    }
}
