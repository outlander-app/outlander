//
//  FileSystem.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

protocol FileSystem {
    func contentsOf(_ directory: URL) -> [URL]
    func fileExists(_ file: URL) -> Bool
    func load(_ file: URL) -> Data?
    func append(_ data: String, to fileUrl: URL) throws
    func write(_ content: String, to fileUrl: URL)
    func write(_ data: Data, to fileUrl: URL) throws
    func foldersIn(directory: URL) -> [URL]
    func access(_ handler: @escaping () -> Void)
    func ensure(folder url: URL) throws
}

class LocalFileSystem: FileSystem {
    let settings: ApplicationSettings

    init(_ settings: ApplicationSettings) {
        self.settings = settings
    }

    func contentsOf(_ directory: URL) -> [URL] {
        var result: [URL] = []

        access {
            do {
                result = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            } catch {
                print("File load error: \(error)")
            }
        }

        return result
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

    func append(_ data: String, to fileUrl: URL) throws {
        try ensure(folder: fileUrl.deletingLastPathComponent())
        try access {
            try data.appendLine(to: fileUrl)
        }
    }

    func append(_ data: Data, to fileUrl: URL) throws {
        try ensure(folder: fileUrl.deletingLastPathComponent())
        access {
            try? data.write(to: fileUrl)
        }
    }

    func write(_ content: String, to fileUrl: URL) {
        access {
            do {
                try content.write(to: fileUrl, atomically: true, encoding: .utf8)
            } catch {}
        }
    }

    func write(_ data: Data, to fileUrl: URL) throws {
        try access {
            try data.write(to: fileUrl)
        }
    }

    func foldersIn(directory: URL) -> [URL] {
        var directories: [URL] = []
        access {
            guard let items = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles, .skipsPackageDescendants]) else {
                return
            }

            for item in items {
                if item.hasDirectoryPath {
                    directories.append(item)
                }
            }
        }

        return directories.sorted(by: { $0.absoluteString < $1.absoluteString })
    }

    func access(_ handler: @escaping () -> Void) {
        settings.paths.rootUrl.access(handler)
    }

    func access(_ handler: @escaping () throws -> Void) throws {
        try settings.paths.rootUrl.accessThrow(handler)
    }

    func ensure(folder url: URL) throws {
        try access {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
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

    func accessThrow(_ handler: @escaping () throws -> Void) throws {
        if !startAccessingSecurityScopedResource() {
            print("startAccessingSecurityScopedResource returned false. This directory might not need it, or this URL might not be a security scoped URL, or maybe something's wrong?")
        }

        try handler()

        stopAccessingSecurityScopedResource()
    }

    func checkFileExist() -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
