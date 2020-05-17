//
//  PlayCommandHandler.swift
//  Outlander
//
//  Created by Joseph McBride on 5/15/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation
import AppKit

class PlayCommandHandler : NSObject, ICommandHandler, NSSoundDelegate {
    var command = "#play"

    let validCommands = ["clear", "stop"]

    var sounds:[NSSound] = []
    let files: FileSystem

    init(_ files: FileSystem) {
        self.files = files
    }

    func handle(_ command: String, with context: GameContext) {
        let commands = command[5...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).components(separatedBy: " ")

        guard commands.count > 0 else {
            removeStoppedSounds()
            return
        }
        
        if commands.count == 1 && validCommands.contains(commands[0].lowercased()) {
            switch commands[0].lowercased() {
            case "clear", "stop":
                self.stop()
                break
            default:
                break
            }
        } else {
            let joined = commands.joined(separator: " ")
            guard joined.count > 0 else {
                context.events.echoError("Usage: #play <file name.mp3>")
                removeStoppedSounds()
                return
            }
            self.play(joined, context: context)
        }

        removeStoppedSounds()
    }

    func play(_ soundFile: String, context: GameContext) {

        var file = URL(fileURLWithPath: soundFile)

        if !file.checkFileExist() {
            let outlanderFile = context.applicationSettings.paths.sounds.appendingPathComponent(soundFile)

            if !outlanderFile.checkFileExist() {
                context.events.echoError("Could not find audio file at '\(file.path)' or '\(outlanderFile.path)'.")
                return
            }

            file = outlanderFile
        }

        self.files.access {
            if let sound = NSSound(contentsOf: file, byReference: true) {
                sound.setName(file.lastPathComponent)
                sound.delegate = self
                self.sounds.append(sound)
                sound.play()
            } else {
                context.events.echoError("Could not play audio file at '\(file.path)'")
            }
        }
    }

    func stop() {
        for index in stride(from: self.sounds.count, through: 1, by: -1) {
            let sound = sounds[index - 1]
            if sound.isPlaying {
                sound.stop()
            }
        }
    }

    func removeStoppedSounds() {
        for index in stride(from: self.sounds.count, through: 1, by: -1) {
            let sound = sounds[index - 1]
            if !sound.isPlaying {
                sounds.remove(at: index - 1)
            }
        }
    }

    func sound(_ sound: NSSound, didFinishPlaying flag: Bool) {
        if let idx = sounds.firstIndex(of: sound) {
            sound.delegate = nil
            sounds.remove(at: idx)
        }
    }
}
