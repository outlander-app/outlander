//
//  ApplicationSettings.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class ApplicationSettings {
    var paths = ApplicationPaths()
    var profile = ProfileSettings()

    var downloadPreReleaseVersions = false
    var checkForApplicationUpdates = false
    var variableTimeFormat = "hh:mm:ss a"
    var variableDateFormat = "yyyy-MM-dd"
    var variableDatetimeFormat = "yyyy-MM-dd hh:mm:ss a"

    var authenticationServerAddress = "eaccess.play.net"
    var authenticationServerPort: UInt16 = 7910

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
        authenticationServerAddress = settings.authenticationServerAddress
        authenticationServerPort = UInt16(settings.authenticationServerPort)
    }

    func toDto() -> ApplicationSettingsDto {
        let dto = ApplicationSettingsDto()
        dto.defaultProfile = profile.name
        dto.downloadPreReleaseVersions = downloadPreReleaseVersions.toYesNoString()
        dto.checkForApplicationUpdates = checkForApplicationUpdates.toYesNoString()
        dto.variableDateFormat = variableDateFormat
        dto.variableTimeFormat = variableTimeFormat
        dto.variableDatetimeFormat = variableDatetimeFormat
        dto.authenticationServerAddress = authenticationServerAddress
        dto.authenticationServerPort = Int(authenticationServerPort)
        return dto
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
        LocalFileSystem(applicationSettings).foldersIn(directory: applicationSettings.paths.profiles).map { $0.lastPathComponent }.sorted()
    }
}
