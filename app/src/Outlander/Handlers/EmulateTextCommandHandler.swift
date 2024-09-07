//
//  EmulateTextCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 9/6/24.
//  Copyright © 2024 Joe McBride. All rights reserved.
//

import Foundation

class EmulateTextCommandHandler: ICommandHandler {
    var command = "#emulate"

    private let files: FileSystem
    private let log = LogManager.getLog(String(describing: EmulateTextCommandHandler.self))
    let queue = DispatchQueue(label: "swiftlee.concurrent.queue", qos: .background)

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ input: String, with: GameContext) {
        let commands = input[command.count...].trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ").filter { !$0.isEmpty }

        if commands.isEmpty {
            return
        }

        let fileName = commands[0]
        let filePath = with.applicationSettings.paths.logs.appendingPathComponent(fileName)

        if files.fileExists(filePath) {
            guard let data = files.load(filePath) else {
                return
            }

            guard let fileString = String(data: data, encoding: .utf8) else {
                return
            }

            let lines = fileString.components(separatedBy: .newlines)

            for line in lines {
                queue.async {
                    with.events2.emulateGameText(line + "\r\n")
                }
            }
        }
    }
}
