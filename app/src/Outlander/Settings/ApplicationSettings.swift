//
//  ApplicationSettings.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class ApplicationSettings {
    var paths:ApplicationPaths = ApplicationPaths()
    var profile = ProfileSettings()

    var downloadPreReleaseVersions = false
    var checkForApplicationUpdates = false
    var variableTimeFormat = "hh:mm:ss a"
    var variableDateFormat = "yyyy-MM-dd"
    var variableDatetimeFormat = "yyyy-MM-dd hh:mm:ss a"

    var currentProfilePath: URL {
        get {
            return paths.profiles.appendingPathComponent(profile.name)
        }
    }

    func update(_ settings:ApplicationSettingsDto) {
        self.downloadPreReleaseVersions = settings.downloadPreReleaseVersions.toBool() ?? false
        self.checkForApplicationUpdates = settings.checkForApplicationUpdates.toBool() ?? true
        self.variableDateFormat = settings.variableDateFormat
        self.variableTimeFormat = settings.variableTimeFormat
        self.variableDatetimeFormat = settings.variableDatetimeFormat
        self.profile.name = settings.defaultProfile
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
}

class ApplicationPaths {

    init() {
        rootUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    var rootUrl: URL
    
    var config: URL {
        get {
            return rootUrl.appendingPathComponent("Config")
        }
    }
    
    var profiles: URL {
        get {
            return config.appendingPathComponent("Profiles")
        }
    }
    
    var layout: URL {
        get {
            return config.appendingPathComponent("Layout")
        }
    }
    
    var maps: URL {
        get {
            return rootUrl.appendingPathComponent("Maps")
        }
    }
    
    var logs: URL {
        get {
            return rootUrl.appendingPathComponent("Logs")
        }
    }

    var sounds: URL {
        get {
            return rootUrl.appendingPathComponent("Sounds")
        }
    }
}
