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

    var delayedTask: DispatchWorkItem?
    var queue = Queue<String>()
    var next: DispatchWorkItem?

    func handle(_ text: String, with context: GameContext) {
        let data = text[5...].trimmingCharacters(in: .whitespacesAndNewlines)
        let split = data.components(separatedBy: " ")

        if split.count > 0, let wait = Double(split[0]) {
            _ = delay(wait) {
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

        delayedTask?.cancel()
        delayedTask = delay(roundtime - 0.5) {
            self.processQueue(context)
        }
    }

    func processQueue(_ context: GameContext) {
        while let data = queue.dequeue() {
            context.events.sendCommand(Command2(command: data, preset: "scriptinput"))
        }
    }
}
