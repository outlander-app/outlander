//
//  ScriptLoader.swift
//  Outlander
//
//  Created by Joe McBride on 11/25/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

struct ScriptLoadResult {
    var file: URL?
    var lines: [String]
}

protocol IScriptLoader {
    func exists(_ file: String) -> Bool
    func load(_ fileName: String, echo: Bool) -> ScriptLoadResult
}

class InMemoryScriptLoader: IScriptLoader {
    var lines: [String: [String]] = [:]

    func exists(_: String) -> Bool {
        lines.count > 0
    }

    func load(_ fileName: String, echo _: Bool) -> ScriptLoadResult {
        ScriptLoadResult(file: URL(string: fileName, relativeTo: nil), lines: lines[fileName]!)
    }
}

class ScriptLoader: IScriptLoader {
    private var files: FileSystem
    private var context: GameContext

    init(_ files: FileSystem, context: GameContext) {
        self.files = files
        self.context = context
    }

    func pathsToCheck() -> [URL] {
        let charName = context.globalVars["charactername"] ?? ""
        let profileName = context.applicationSettings.profile.name
        var paths: [URL] = []

        if !charName.isEmpty {
            paths.append(context.applicationSettings.paths.scripts.appendingPathComponent("\(charName)"))
        }

        if !profileName.isEmpty, profileName != charName {
            paths.append(context.applicationSettings.paths.scripts.appendingPathComponent(profileName))
        }

        paths.append(context.applicationSettings.paths.scripts)

        for folder in files.foldersIn(directory: context.applicationSettings.paths.scripts) {
            paths.append(folder)
        }

        return paths
    }

    func fileToLoad(_ fileName: String, echo: Bool = false) -> URL? {
        let nameToUse = fileName.hasSuffix(".cmd") ? fileName : "\(fileName).cmd"
        for path in pathsToCheck() {
            if echo {
                context.events2.echoText("Searching for '\(nameToUse)' in \(path.path)", preset: "scriptecho", mono: true)
            }
            let fullName = path.appendingPathComponent("\(nameToUse)")
            if files.fileExists(fullName) {
                return fullName
            }
        }
        return nil
    }

    func exists(_ fileName: String) -> Bool {
        fileToLoad(fileName) != nil
    }

    func load(_ fileName: String, echo: Bool = false) -> ScriptLoadResult {
        guard let fileUrl = fileToLoad(fileName, echo: echo) else {
            return ScriptLoadResult(file: nil, lines: [])
        }

        guard let data = files.load(fileUrl) else {
            return ScriptLoadResult(file: nil, lines: [])
        }

        guard let fileString = String(data: data, encoding: .utf8) else {
            return ScriptLoadResult(file: nil, lines: [])
        }

        let lines = fileString.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: .newlines)
        return ScriptLoadResult(file: fileUrl, lines: lines)
    }
}
