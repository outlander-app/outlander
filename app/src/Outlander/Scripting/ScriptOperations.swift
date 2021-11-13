//
//  ScriptOperations.swift
//  Outlander
//
//  Created by Joe McBride on 2/26/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

enum CheckStreamResult {
    case match(String)
    case none
}

class MoveOp: IWantStreamInfo {
    var id = ""
    let target: String

    init(_ target: String) {
        id = UUID().uuidString
        self.target = target
    }

    func stream(_: String, _ commands: [StreamCommand], _: ScriptContext) -> CheckStreamResult {
        for cmd in commands {
            switch cmd {
            case .compass:
                return .match("")
            default:
                continue
            }
        }

        return .none
    }

    func execute(_ script: Script, _: ScriptContext) {
        script.next()
    }
}

class NextRoomOp: IWantStreamInfo {
    var id = ""

    init() {
        id = UUID().uuidString
    }

    func stream(_: String, _ commands: [StreamCommand], _: ScriptContext) -> CheckStreamResult {
        for cmd in commands {
            switch cmd {
            case .compass:
                return .match("")
            default:
                continue
            }
        }

        return .none
    }

    func execute(_ script: Script, _: ScriptContext) {
        // TODO: next after roundtime
        script.next()
    }
}

class WaitforPromptOp: IWantStreamInfo {
    var id = ""

    init() {
        id = UUID().uuidString
    }

    func stream(_: String, _ commands: [StreamCommand], _: ScriptContext) -> CheckStreamResult {
        for cmd in commands {
            switch cmd {
            case .prompt:
                return .match("")
            default:
                continue
            }
        }

        return .none
    }

    func execute(_ script: Script, _: ScriptContext) {
        // TODO: next after roundtime
        script.next()
    }
}

class WaitforOp: IWantStreamInfo {
    var id = ""
    let target: String

    init(_ target: String) {
        id = UUID().uuidString
        self.target = target
    }

    func stream(_ text: String, _: [StreamCommand], _ context: ScriptContext) -> CheckStreamResult {
        let check = context.replaceVars(target)
        return text.range(of: check) != nil
            ? .match(text)
            : .none
    }

    func execute(_ script: Script, _: ScriptContext) {
        script.next()
    }
}

class WaitforReOp: IWantStreamInfo {
    public var id = ""
    var pattern: String
    var groups: [String]

    init(_ pattern: String) {
        id = UUID().uuidString
        self.pattern = pattern
        groups = []
    }

    func stream(_ text: String, _: [StreamCommand], _ context: ScriptContext) -> CheckStreamResult {
        let resolved = context.replaceVars(pattern)
        var txt = text

        let regex = RegexFactory.get(resolved)
        guard let match = regex?.firstMatch(&txt) else {
            return .none
        }
        groups = match.values()
        return groups.count > 0 ? .match(txt) : .none
    }

    func execute(_ script: Script, _ context: ScriptContext) {
        context.setRegexVars(groups)
        script.next()
    }
}
