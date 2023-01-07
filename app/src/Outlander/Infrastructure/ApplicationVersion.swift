//
//  ApplicationVersion.swift
//  Outlander
//
//  Created by Joe McBride on 1/7/23.
//  Copyright © 2023 Joe McBride. All rights reserved.
//

import Foundation

struct ApplicationVersion {
    private static var _appVersion: String?

    static var version: String {
        if let v = _appVersion {
            return v
        }

        _appVersion = buildAppVersion()
        return _appVersion!
    }

    private static func buildAppVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let buildStr = dictionary["CFBundleVersion"] as! String
        var build = ""
        if !buildStr.isEmpty, buildStr != "0" {
            build = ".\(buildStr)"
        }
        return "\(version)\(build)"
    }
}
