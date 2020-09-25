//
//  ApplicationSettings.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class ApplicationSettings {
    var paths: ApplicationPaths = ApplicationPaths()
    var profile = ProfileSettings()

    var downloadPreReleaseVersions = false
    var checkForApplicationUpdates = false
    var variableTimeFormat = "hh:mm:ss a"
    var variableDateFormat = "yyyy-MM-dd"
    var variableDatetimeFormat = "yyyy-MM-dd hh:mm:ss a"

    var authenticationServerAddress = "eaccess.play.net"
    var authenticationServerPort: UInt16 = 7900
    
    var currentProfilePath: URL {
        paths.profiles.appendingPathComponent(profile.name)
    }

    func update(_ settings: ApplicationSettingsDto) {
        downloadPreReleaseVersions = settings.downloadPreReleaseVersions.toBool() ?? false
        checkForApplicationUpdates = settings.checkForApplicationUpdates.toBool() ?? true
        variableDateFormat = settings.variableDateFormat
        variableTimeFormat = settings.variableTimeFormat
        variableDatetimeFormat = settings.variableDatetimeFormat
        profile.name = settings.defaultProfile
    }
}

class ProfileSettings {
    var name = ""
    var account = ""
    var game = ""
    var character = ""
    var logging = false
    var rawLogging = false
    var layout = "default.cfg"

    func update(with credentials: Credentials) {
        account = credentials.account
        game = credentials.game
        character = credentials.character
    }
}

class ApplicationPaths {
    init() {
        rootUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    var rootUrl: URL

    var config: URL {
        rootUrl.appendingPathComponent("Config")
    }

    var profiles: URL {
        config.appendingPathComponent("Profiles")
    }

    var layout: URL {
        config.appendingPathComponent("Layout")
    }

    var maps: URL {
        rootUrl.appendingPathComponent("Maps")
    }

    var logs: URL {
        rootUrl.appendingPathComponent("Logs")
    }

    var sounds: URL {
        rootUrl.appendingPathComponent("Sounds")
    }

    var scripts: URL {
        rootUrl.appendingPathComponent("Scripts")
    }
}

extension GameContext {
    func allProfiles() -> [String] {
        var profiles: [String] = []
        applicationSettings.paths.rootUrl.access {
            let dir = self.applicationSettings.paths.profiles
            guard let items = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]) else {
                return
            }

            for item in items {
                if item.hasDirectoryPath {
                    profiles.append(item.lastPathComponent)
                }
            }
        }

        return profiles.sorted()
    }
}
