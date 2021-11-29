//
//  NSViewExtensions.swift
//  Outlander
//
//  Created by Joe McBride on 11/9/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

extension NSView {
    var isDarkMode: Bool {
        if #available(OSX 10.14, *) {
            if [NSAppearance.Name.darkAqua, NSAppearance.Name.vibrantDark, NSAppearance.Name.accessibilityHighContrastDarkAqua, NSAppearance.Name.accessibilityHighContrastVibrantDark].contains(effectiveAppearance.name) {
                return true
            }
        }
        return false
    }
}
