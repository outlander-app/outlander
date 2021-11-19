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

    func handle(_ text: String, with context: GameContext) {
        let data = text[5...].trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)

        queue.queue(data)

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
