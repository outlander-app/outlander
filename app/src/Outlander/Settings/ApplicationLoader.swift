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
        let layout = WindowLayoutLoader(self.files)
            .load(context.applicationSettings, file: context.applicationSettings.profile.layout)
        context.layout = layout

        AliasLoader(self.files).load(context.applicationSettings, context: context)
        ClassLoader(self.files).load(context.applicationSettings, context: context)
        GagLoader(self.files).load(context.applicationSettings, context: context)
        HighlightLoader(self.files).load(context.applicationSettings, context: context)
        PresetLoader(self.files).load(context.applicationSettings, context: context)
        SubstituteLoader(self.files).load(context.applicationSettings, context: context)
        TriggerLoader(self.files).load(context.applicationSettings, context: context)
        VariablesLoader(self.files).load(context.applicationSettings, context: context)
    }

    func save(_ context: GameContext) {
        AliasLoader(self.files).save(context.applicationSettings, aliases: context.aliases)
    }
}
