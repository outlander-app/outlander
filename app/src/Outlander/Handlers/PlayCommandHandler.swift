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

    func handle(command: String, withContext context: GameContext) {
        let commands = command[5...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).components(separatedBy: " ")

        guard commands.count > 0 else {
            removeStoppedSounds()
            return
        }
        
        if commands.count == 1 && validCommands.contains(commands[0].lowercased()) {
            switch commands[0].lowercased() {
            case "clear", "stop":
                self.stop()
                NSSound.beep()
                return
            default:
                NSSound.beep()
                removeStoppedSounds()
                return
            }
        } else {
            self.play(commands.joined(separator: " "), context: context)
        }

        removeStoppedSounds()
    }

    func play(_ soundFile: String, context: GameContext) {

        var file = URL(fileURLWithPath: soundFile)

        if !self.files.fileExists(file) {
            file = context.applicationSettings.paths.sounds.appendingPathComponent(soundFile)

            if !self.files.fileExists(file) {
                print("could not find \(file)")
                return
            }
        }

        self.files.access {
            if let sound = NSSound(contentsOf: file, byReference: true) {
                print("playing sound \(file)")
                sound.setName(file.lastPathComponent)
                sound.delegate = self
                self.sounds.append(sound)
                sound.play()
            } else {
                print("could not play \(file)")
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
