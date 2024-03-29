//
//  ApplicationLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class ApplicationSettingsDto: Codable {
    static var defaultWindowsToLog = "main, assess, atmospherics, chatter, combat, conversation, death, familiar, group, logons, ooc, talk, thoughts, whispers, shopwindow"

    var defaultProfile = "Default"
    var downloadPreReleaseVersions: String = "no"
    var checkForApplicationUpdates: String = "no"
    var variableTimeFormat = "hh:mm:ss a"
    var variableDateFormat = "yyyy-MM-dd"
    var variableDatetimeFormat = "yyyy-MM-dd hh:mm:ss a"

    var authenticationServerAddress = "eaccess.play.net"
    var authenticationServerPort: Int = 7910

    var windowsToLog: String?

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultProfile = try container.decodeIfPresent(String.self, forKey: .defaultProfile) ?? "Default"
        if defaultProfile.isEmpty {
            defaultProfile = "Default"
        }
        downloadPreReleaseVersions = try container.decodeIfPresent(String.self, forKey: .downloadPreReleaseVersions) ?? "no"
        checkForApplicationUpdates = try container.decodeIfPresent(String.self, forKey: .checkForApplicationUpdates) ?? "no"
        variableTimeFormat = try container.decodeIfPresent(String.self, forKey: .variableTimeFormat) ?? "hh:mm:ss a"
        variableDateFormat = try container.decodeIfPresent(String.self, forKey: .variableDateFormat) ?? "yyyy-MM-dd"
        variableDatetimeFormat = try container.decodeIfPresent(String.self, forKey: .variableDatetimeFormat) ?? "yyyy-MM-dd hh:mm:ss a"
        authenticationServerAddress = try container.decodeIfPresent(String.self, forKey: .authenticationServerAddress) ?? "eaccess.play.net"
        authenticationServerPort = try container.decodeIfPresent(Int.self, forKey: .authenticationServerPort) ?? 7910
        windowsToLog = try container.decodeIfPresent(String.self, forKey: .windowsToLog) ?? ApplicationSettingsDto.defaultWindowsToLog
    }
}

class ApplicationLoader {
    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ paths: ApplicationPaths, context: GameContext) {
        ensureFolders(paths: paths, context: context)

        _ = IconLoader(files).load(paths)

        let fileUrl = paths.config.appendingPathComponent("app.cfg")

        guard let data = files.load(fileUrl) else {
            return
        }

        let decoder = JSONDecoder()
        guard let settings = try? decoder.decode(ApplicationSettingsDto.self, from: data) else {
            return
        }
        context.applicationSettings.update(settings)
        context.globalVars["profilename"] = settings.defaultProfile
    }

    func save(_ paths: ApplicationPaths, context: GameContext) {
        let appSettings = context.applicationSettings.toDto()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(appSettings) else {
            return
        }

        let fileUrl = paths.config.appendingPathComponent("app.cfg")
        try? files.write(data, to: fileUrl)
    }

    private func ensureFolders(paths: ApplicationPaths, context: GameContext) {
        let folders = [
            paths.config,
            paths.profiles,
            paths.layout,
            paths.maps,
            paths.logs,
            paths.sounds,
            paths.scripts,
            paths.icons,
            paths.plugins,
            context.applicationSettings.currentProfilePath,
        ]

        for folder in folders {
            do {
                try files.ensure(folder: folder)
            } catch {
                context.events2.echoError("Error creating to create folder \(folder.path)")
            }
        }
    }
}

class ProfileConfigLoader {
    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ context: GameContext) {
        let fileUrl = context.applicationSettings.currentProfilePath.appendingPathComponent("config.cfg")

        guard let data = files.load(fileUrl) else {
            return
        }

        guard var content = String(data: data, encoding: .utf8) else {
            return
        }

        let profile = context.applicationSettings.profile

        let account = RegexFactory.get("Account: (.+)")?.firstMatch(&content)
        profile.account = account?.valueAt(index: 1)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let game = RegexFactory.get("Game: (.+)")?.firstMatch(&content)
        profile.game = game?.valueAt(index: 1)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let character = RegexFactory.get("Character: (.+)")?.firstMatch(&content)
        profile.character = character?.valueAt(index: 1)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let logging = RegexFactory.get("Logging: (.+)")?.firstMatch(&content)
        profile.logging = logging?.valueAt(index: 1)?.toBool() ?? false

        let rawlogging = RegexFactory.get("RawLogging: (.+)")?.firstMatch(&content)
        profile.rawLogging = rawlogging?.valueAt(index: 1)?.toBool() ?? false

        let layout = RegexFactory.get("Layout: (.+)")?.firstMatch(&content)
        profile.layout = layout?.valueAt(index: 1)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "default.cfg"

        let ignore = RegexFactory.get("MonsterIgnore: (.+)")?.firstMatch(&content)
        profile.monsterIgnore = ignore?.valueAt(index: 1)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func save(_ context: GameContext) {
        let fileUrl = context.applicationSettings.currentProfilePath.appendingPathComponent("config.cfg")

        var lines: [String] = []

        lines.append("Account: \(context.applicationSettings.profile.account)")
        lines.append("Game: \(context.applicationSettings.profile.game)")
        lines.append("Character: \(context.applicationSettings.profile.character)")
        lines.append("Logging: \(context.applicationSettings.profile.logging ? "yes" : "no")")
        lines.append("RawLogging: \(context.applicationSettings.profile.rawLogging ? "yes" : "no")")
        lines.append("Layout: \(context.applicationSettings.profile.layout)")
        lines.append("MonsterIgnore: \(context.applicationSettings.profile.monsterIgnore)")

        let content = lines.joined(separator: "\n")
        files.write(content, to: fileUrl)
    }
}

class ProfileLoader {
    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ context: GameContext) {
        ProfileConfigLoader(files).load(context)

        let layout = WindowLayoutLoader(files)
            .load(context.applicationSettings, file: context.applicationSettings.profile.layout)
        context.layout = layout

        AliasLoader(files).load(context.applicationSettings, context: context)
        ClassLoader(files).load(context.applicationSettings, context: context)
        GagLoader(files).load(context.applicationSettings, context: context)
        HighlightLoader(files).load(context.applicationSettings, context: context)
        PresetLoader(files).load(context.applicationSettings, context: context)
        MacroLoader(files).load(context.applicationSettings, context: context)
        SubstituteLoader(files).load(context.applicationSettings, context: context)
        TriggerLoader(files).load(context.applicationSettings, context: context)
        VariablesLoader(files).load(context.applicationSettings, context: context)
    }

    func save(_ context: GameContext) {
        ProfileConfigLoader(files).save(context)
        AliasLoader(files).save(context.applicationSettings, aliases: context.aliases)
        ClassLoader(files).save(context.applicationSettings, classes: context.classes)
        GagLoader(files).save(context.applicationSettings, gags: context.gags)
        HighlightLoader(files).save(context.applicationSettings, highlights: context.highlights.all())
        MacroLoader(files).save(context.applicationSettings, macros: context.macros)
        PresetLoader(files).save(context.applicationSettings, presets: context.presets)
        SubstituteLoader(files).save(context.applicationSettings, subsitutes: context.substitutes.all())
        TriggerLoader(files).save(context.applicationSettings, triggers: context.triggers)
        VariablesLoader(files).save(context.applicationSettings, variables: context.globalVars)
    }
}
