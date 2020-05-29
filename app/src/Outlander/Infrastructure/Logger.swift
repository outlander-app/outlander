//
//  Logger.swift
//  Outlander
//
//  Created by Joseph McBride on 5/17/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

protocol ILogger {
    func info(_ message: String)
    func warn(_ message: String)
    func error(_ message: String)

    func stream(_ data: String)
    func rawStream(_ data: String)

    func scriptLog(_ data: String, to: String)
}

class LogManager {
    private static let nullLogInstance = NullLog()

    static var getLog: (String) -> ILogger = { _ in LogManager.nullLogInstance }
}

class NullLog: ILogger {
    func info(_: String) {}

    func warn(_: String) {}

    func error(_: String) {}

    func stream(_: String) {}

    func rawStream(_: String) {}

    func scriptLog(_: String, to _: String) {}
}

class PrintLogger: ILogger {
    let name: String

    init(_ name: String) {
        self.name = name
    }

    func info(_ message: String) {
        log(message, level: "INFO")
    }

    func warn(_ message: String) {
        log(message, level: "WARN")
    }

    func error(_ message: String) {
        log(message, level: "ERROR")
    }

    func stream(_ data: String) {
        log(data, level: "STREAM")
    }

    func rawStream(_ data: String) {
        log(data, level: "RAWSTREAM")
    }

    func scriptLog(_ data: String, to: String) {
        log(data, level: "SCRIPTLOG(\(to))")
    }

    private func log(_ data: String, level: String) {
        print("\(level): \(data)")
    }
}
