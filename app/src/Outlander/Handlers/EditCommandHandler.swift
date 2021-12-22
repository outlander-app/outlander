//
//  EditCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/21/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import AppKit
import Foundation

class EditCommandHandler: ICommandHandler {
    var command = "#edit"

    private var files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ input: String, with context: GameContext) {
        let scriptFileName = input[command.count...].trimLeadingWhitespace()
        guard scriptFileName.count > 0 else {
            return
        }

        let loader = ScriptLoader(files, context: context)
        guard let url = loader.fileToLoad(scriptFileName) else {
            let newFileName = scriptFileName.hasSuffix(".cmd") ? scriptFileName : scriptFileName + ".cmd"
            let newFileUrl = context.applicationSettings.paths.scripts.appendingPathComponent(newFileName)
            try? files.append("#  \(scriptFileName)\n", to: newFileUrl)

            files.access {
                NSWorkspace.shared.openFile(newFileUrl.absoluteString)
            }
            return
        }

        files.access {
            NSWorkspace.shared.openFile(url.absoluteString)
        }
    }
}
