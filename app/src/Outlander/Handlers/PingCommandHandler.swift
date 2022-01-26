//
//  PingCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/10/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class PingCommandHandler: ICommandHandler {
    var command = "#ping"

    private var pinger: Pinger?

    func handle(_: String, with context: GameContext) {
        let target = "ping.play.net"
        pinger = Pinger(target, count: 3) { result in
            let hasError = result.contains("Error")
            let display = hasError ? result : "\(result)ms"

            if !hasError {
                context.globalVars["serverping"] = result
                context.events2.echoText("PING: \(display)")
            } else {
                context.events2.echoText("PING: \(display)", preset: "scripterror")
            }

            context.events2.sendCommand(Command2(command: "#parse PING: \(display)", isSystemCommand: true))
            self.pinger = nil
        }
        pinger?.ping()
    }
}

class Pinger {
    typealias PingCompletion = ((String) -> Void)

    var target: String
    var count: Int
    var results: [Double] = []
    var done: PingCompletion

    init(_ target: String, count: Int, done: @escaping PingCompletion) {
        self.target = target
        self.count = count
        self.done = done
    }

    func ping() {
        count -= 1
        PlainPing.ping(target, withTimeout: 1.0) { time, error in
            print("pinged \(String(describing: time)) \(String(describing: error))")
            if error != nil {
                self.done("Error: \(error!.localizedDescription)")
                return
            }
            if let time = time {
                self.results.append(time)
            }
            if self.count > 0 {
                self.ping()
            } else {
                let sum = self.results.reduce(0, +)
                let time = sum / Double(self.results.count)
                self.done(time.formattedNumber)
            }
        }
    }
}
