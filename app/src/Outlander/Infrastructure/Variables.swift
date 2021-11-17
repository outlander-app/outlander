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

    func keys() -> [String] {
        lockQueue.sync(flags: .barrier) {
            vars.map { $0.key }.sorted(by: { $0.count > $1.count })
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

struct VariableSetting {
    var token: String
    var sortedKeys: [String]
    var values: (String) -> String?
}

class VariableContext {
    var settings: [VariableSetting] = []

    var keys: [String] {
        Array(Set(settings.map { $0.token }))
    }

    func add(_ token: String, sortedKeys: [String], values: @escaping ((String) -> String?)) {
        settings.append(VariableSetting(token: token, sortedKeys: sortedKeys, values: values))
    }
}

class VariableReplacer {
    func replace(_ input: String, globalVars: Variables) -> String {
        let context = VariableContext()
        context.add("$", sortedKeys: globalVars.keys(), values: { key in globalVars[key] })
        return replace(input, context: context)
    }

    func replace(_ input: String, context: VariableContext) -> String {
        var result = replaceIndexedVars(input, context: context)

        guard hasPotentialVars(input, context: context) else {
            return input
        }

        func doReplace() {
            for setting in context.settings {
                simplify(prefix: setting.token, target: &result, sortedKeys: setting.sortedKeys, value: setting.values)
            }
        }

        let max = 15
        var count = 0
        var last = result

        repeat {
            doReplace()
            last = result
            count += 1
        } while count < max && last != result && hasPotentialVars(result, context: context)

        return result
    }

    func replaceIndexedVars(_ result: String, context: VariableContext) -> String {
        guard result.index(of: "[") != nil || result.index(of: "(") != nil else {
            return result
        }

        let tokens = VariableTokenizer().read(result)
        guard tokens.count > 0 else {
            return result
        }

        var results: [String] = []
        for v in tokens {
            switch v {
            case let .value(val):
                results.append(val)
            case let .indexed(varname, index):
                let name = replace(varname, context: context)
                let idx = replace(index, context: context)

                guard let number = Int(idx) else {
                    results.append("\(name)[\(idx)]")
                    continue
                }

                let list = name.components(separatedBy: "|")
                guard number > -1, number < list.count else {
                    results.append("\(name)[\(idx)]")
                    continue
                }

                let val = list[number]
                results.append(val)
            }
        }

        return results.joined(separator: "")
    }

    func hasPotentialVars(_ input: String, context: VariableContext) -> Bool {
        for key in context.keys {
            if input.range(of: key) != nil {
                return true
            }
        }

        return false
    }

    private func simplify(prefix: String, target: inout String, sortedKeys: [String], value: (String) -> String?) {
        guard target.contains(prefix) else {
            return
        }

        func doReplace() {
            for key in sortedKeys {
                let replaceCandidate = "\(prefix)\(key)"
                target = target.replacingOccurrences(of: replaceCandidate, with: value(key) ?? "")
            }
        }

        let max = 15
        var count = 0

        repeat {
            doReplace()
            count += 1
        } while count < max && target.contains(prefix)
    }
}
