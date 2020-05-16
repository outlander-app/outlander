//
//  ApplicationLoader.swift
//  Outlander
//
//  Created by Joseph McBride on 5/8/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

class ApplicationLoader {
    func load(_ context: GameContext) {
    }
}

class ProfileLoader {
    let files: FileSystem
    
    init(_ files: FileSystem) {
        self.files = files
    }

    func load(_ context: GameContext) {
        let layout = WindowLayoutLoader(self.files).load(context.applicationSettings, file: "default.cfg")
        context.layout = layout

        ClassLoader(self.files).load(context.applicationSettings, context: context)
        PresetLoader(self.files).load(context.applicationSettings, context: context)
        VariablesLoader(self.files).load(context.applicationSettings, context: context)
    }
}
