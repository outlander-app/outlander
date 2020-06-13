//
//  FileSystem.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

protocol FileSystem {
    func fileExists(_ file: URL) -> Bool
    func load(_ file: URL) -> Data?
    func write(_ content: String, to fileUrl: URL)
    func access(_ handler: @escaping () -> Void)
}

class LocalFileSystem: FileSystem {
    let settings: ApplicationSettings

    init(_ settings: ApplicationSettings) {
        self.settings = settings
    }

    func fileExists(_ file: URL) -> Bool {
        file.checkFileExist()
    }

    func load(_ file: URL) -> Data? {
        var data: Data?

        access {
            data = try? Data(contentsOf: file)
        }

        return data
    }

    func write(_ content: String, to fileUrl: URL) {
        access {
            do {
                try content.write(to: fileUrl, atomically: true, encoding: .utf8)
            } catch {}
        }
    }

    func access(_ handler: @escaping () -> Void) {
        settings.paths.rootUrl.access(handler)
    }
}

extension URL {
    func access(_ handler: @escaping () -> Void) {
        if !startAccessingSecurityScopedResource() {
            print("startAccessingSecurityScopedResource returned false. This directory might not need it, or this URL might not be a security scoped URL, or maybe something's wrong?")
        }

        handler()

        stopAccessingSecurityScopedResource()
    }

    func checkFileExist() -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
