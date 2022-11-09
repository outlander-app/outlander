//
//  Logger.swift
//  Outlander
//
//  Created by Joseph McBride on 5/17/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

protocol ILogger {
    var name: String { get }

    func info(_ message: String)
    func warn(_ message: String)
    func error(_ message: String)

    func stream(_ data: String)
    func rawStream(_ data: String)

    func scriptLog(_ data: String, to: String)
}

enum LogManager {
    private static let nullLogInstance = NullLog()

    static var getLog: (String) -> ILogger = { _ in LogManager.nullLogInstance }
}

class NullLog: ILogger {
    var name: String = "nullo"

    func info(_: String) {}

    func warn(_: String) {}

    func error(_: String) {}

    func stream(_: String) {}

    func rawStream(_: String) {}

    func scriptLog(_: String, to _: String) {}
}

class PrintLogger: ILogger {
    var name: String

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
        print("\(name)-\(level): \(data)")
    }
}

class CompositeLoggers: ILogger {
    private var loggers: [ILogger] = []

    var name: String = "composite"

    func add(_ logger: ILogger) {
        loggers.append(logger)
    }

    func info(_ message: String) {
        for log in loggers {
            log.info(message)
        }
    }

    func warn(_ message: String) {
        for log in loggers {
            log.warn(message)
        }
    }

    func error(_ message: String) {
        for log in loggers {
            log.error(message)
        }
    }

    func stream(_ data: String) {
        for log in loggers {
            log.stream(data)
        }
    }

    func rawStream(_ data: String) {
        for log in loggers {
            log.warn(data)
        }
    }

    func scriptLog(_ data: String, to: String) {
        for log in loggers {
            log.scriptLog(data, to: to)
        }
    }
}

class FileLogger: ILogger {
    private var files: FileSystem
    private var root: URL
    private var fileStreamName: URL
    private var rawFileStreamName: URL

    var name: String

    init(_ name: String, root: URL, files: FileSystem) {
        self.name = name
        self.root = root
        self.files = files

        fileStreamName = root.appendingPathComponent(name)
        let rawfileName = String(name.dropLast(4)) + "-raw.txt"
        rawFileStreamName = root.appendingPathComponent(rawfileName)
    }

    func info(_: String) {}

    func warn(_: String) {}

    func error(_ data: String) {
        guard !data.isEmpty else {
            return
        }
        try? files.append(data, to: fileStreamName)
    }

    func stream(_ data: String) {
        guard !data.isEmpty else {
            return
        }
        try? files.append(data, to: fileStreamName)
    }

    func rawStream(_ data: String) {
        guard !data.isEmpty else {
            return
        }
        try? files.append(data, to: rawFileStreamName)
    }

    func scriptLog(_: String, to _: String) {}
}
