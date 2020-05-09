//
//  FileSystem.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

protocol FileSystem {
    func load(file:URL) -> Data?
    func save(file:URL, content:String)
    func access(handler: @escaping ()->Void)
}

class LocalFileSystem: FileSystem {

    let settings: ApplicationSettings

    init(_ settings: ApplicationSettings) {
        self.settings = settings
    }

    func load(file: URL) -> Data? {
        var data:Data? = nil

        self.settings.paths.rootUrl.access {
           data = try? Data(contentsOf: file)
        }

        return data
    }

    func save(file: URL, content: String) {
    }
    
    func access(handler: @escaping ()->Void) {
        
        if !self.settings.paths.rootUrl.startAccessingSecurityScopedResource() {
            print("startAccessingSecurityScopedResource returned false. This directory might not need it, or this URL might not be a security scoped URL, or maybe something's wrong?")
        }

        handler()
        
        self.settings.paths.rootUrl.stopAccessingSecurityScopedResource()
    }
}

extension URL {

    func access(handler: @escaping ()->Void) {

        if !self.startAccessingSecurityScopedResource() {
            print("startAccessingSecurityScopedResource returned false. This directory might not need it, or this URL might not be a security scoped URL, or maybe something's wrong?")
        }

        handler()

        self.stopAccessingSecurityScopedResource()
    }
}
