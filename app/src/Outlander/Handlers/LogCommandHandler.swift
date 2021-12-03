//
//  LogCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 11/28/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

extension String {
    func appendLine(to url: URL) throws {
        try "\(self)\n".append(to: url)
    }

    func append(to url: URL) throws {
        try data(using: .utf8)?.append(to: url)
    }
}

extension Data {
    func append(to url: URL) throws {
        guard let handle = try? FileHandle(forWritingTo: url) else {
            try write(to: url, options: .atomic)
            return
        }

        defer {
            handle.closeFile()
        }

        handle.seekToEndOfFile()
        handle.write(self)
    }
}

class LogCommandHandler: ICommandHandler {
    private var files: FileSystem

    var command = "#log"

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ command: String, with context: GameContext) {
        var commands = command[4...].trimmingCharacters(in: .whitespacesAndNewlines)

        let regex = RegexFactory.get("^(>([\\w\\.\\$%-]+)\\s)?(.*)")
        guard let match = regex?.firstMatch(&commands) else {
            return
        }

        var fileName = match.valueAt(index: 2) ?? ""
        var text = match.valueAt(index: 3) ?? ""

        fileName = (fileName == "" || fileName == "") ? "\(context.applicationSettings.profile.name)-\(context.applicationSettings.profile.game).txt" : fileName

        text = text.replacingOccurrences(of: "\\n", with: "\n")
        text = text.replacingOccurrences(of: "\\r", with: "\r")

        do {
            let file = context.applicationSettings.paths.logs.appendingPathComponent(fileName)
            try files.append(text, to: file)
        } catch {
            context.events.echoError("Error trying to write to file:\n  \(error)")
        }
    }
}
