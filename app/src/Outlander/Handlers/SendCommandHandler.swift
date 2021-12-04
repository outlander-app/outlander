//
//  SendCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 10/25/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class SendCommandHandler: ICommandHandler {
    var command = "#send"

    var delayedTask: DelayedTask = DelayedTask()
    var queue = Queue<String>()
    var delayOffset: Double = 0.3

    func handle(_ text: String, with context: GameContext) {
        let data = text[command.count...].trimmingCharacters(in: .whitespacesAndNewlines)

        guard !data.isEmpty else {
            context.events.echoText("#send queue:")
            let messages = queue.all
            for cmd in messages {
                context.events.echoText("  \(cmd)")
            }
            if messages.count > 0 {
                context.events.echoText("\n")
            }
            return
        }

        let split = data.components(separatedBy: " ")

        if split.count > 0, let wait = Double(split[0]) {
            delay(wait - delayOffset) {
                self.queue.queue(split.dropFirst().joined(separator: " "))
                self.processQueueWithRoundtime(context)
            }
            return
        }

        queue.queue(data)
        processQueueWithRoundtime(context)
    }

    func processQueueWithRoundtime(_ context: GameContext) {
        guard let roundtime = Double(context.globalVars["roundtime"] ?? "0") else {
            processQueue(context)
            return
        }

        guard roundtime > 0 else {
            processQueue(context)
            return
        }

        delayedTask.set(roundtime - delayOffset) {
            self.processQueue(context)
        }
    }

    func processQueue(_ context: GameContext) {
        while let data = queue.dequeue() {
            context.events.sendCommand(Command2(command: data, preset: "scriptinput"))
        }
    }
}
