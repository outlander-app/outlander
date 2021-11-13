//
//  Variables.swift
//  Outlander
//
//  Created by Joe McBride on 11/12/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

protocol IClock {
    var now: Date { get }
}

class Clock: IClock {
    private var getDate: () -> Date

    convenience init() {
        self.init { Date() }
    }

    init(_ getDate: @escaping () -> Date) {
        self.getDate = getDate
    }

    public var now: Date {
        getDate()
    }
}

public typealias VariableValueFunction = () -> String?

enum DynamicValue {
    case value(String?)
    case dynamic(VariableValueFunction)

    var rawValue: String? {
        switch self {
        case let .value(val): return val
        case let .dynamic(dynamic): return dynamic()
        }
    }
}

class Variables {
    private let lockQueue = DispatchQueue(label: "com.outlanderapp.variables.\(UUID().uuidString)")
    private var vars: [String: DynamicValue] = [:]
    private var events: Events
    private var settings: ApplicationSettings
    private var clock: IClock

    private static var dynamicKeys: [String] = ["date", "datetime", "time"]

    static var dateFormatter = DateFormatter()

    init(events: Events, settings: ApplicationSettings, clock: IClock = Clock()) {
        self.events = events
        self.settings = settings
        self.clock = clock

        addDynamics()
    }

    subscript(key: String) -> String? {
        get {
            lockQueue.sync {
                vars[key]?.rawValue
            }
        }
        set(newValue) {
            lockQueue.sync(flags: .barrier) {
                guard !Variables.dynamicKeys.contains(key) else {
                    return
                }

                let res = newValue ?? ""
                guard vars[key]?.rawValue != res else {
                    return
                }
                vars[key] = .value(res)
                DispatchQueue.main.async {
                    self.events.variableChanged(key, value: res)
                }
            }
        }
    }

    var count: Int {
        lockQueue.sync {
            vars.count
        }
    }

    func removeAll() {
        lockQueue.sync(flags: .barrier) {
            vars.removeAll()
            addDynamics()
        }
    }

    func sorted() -> [(String, DynamicValue)] {
        lockQueue.sync(flags: .barrier) {
            vars.sorted(by: { $0.key < $1.key })
        }
    }

    private func addDynamics() {
        vars["date"] = .dynamic {
            Variables.dateFormatter.dateFormat = self.settings.variableDateFormat
            return Variables.dateFormatter.string(from: self.clock.now)
        }

        vars["datetime"] = .dynamic {
            Variables.dateFormatter.dateFormat = self.settings.variableDatetimeFormat
            return Variables.dateFormatter.string(from: self.clock.now)
        }

        vars["time"] = .dynamic {
            Variables.dateFormatter.dateFormat = self.settings.variableTimeFormat
            return Variables.dateFormatter.string(from: self.clock.now)
        }
    }
}
