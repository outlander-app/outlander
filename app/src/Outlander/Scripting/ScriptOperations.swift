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

class WaitforOp : IWantStreamInfo {
    var id = ""
    let target:String

    init(_ target:String) {
        self.id = UUID().uuidString
        self.target = target
    }

    func stream(_ text: String, _ context: ScriptContext) -> CheckStreamResult {
        // TODO: resolve target before comparision, it could contain a variable
        return text.range(of: target) != nil
            ? CheckStreamResult.match(text)
            : CheckStreamResult.none
    }

    func execute(_ script: Script, _ context: ScriptContext) {
        script.next()
    }
}

class WaitforReOp : IWantStreamInfo {
    public var id = ""
    var pattern:String
    var groups:[String]

    init(_ pattern:String) {
        self.id = UUID().uuidString
        self.pattern = pattern
        self.groups = []
    }

    func stream(_ text: String, _ context: ScriptContext) -> CheckStreamResult {
        // TODO: resolve pattern before comparision, it could contain a variable
        var txt = text

        let regex = RegexFactory.get(pattern)
        guard let match = regex?.firstMatch(&txt) else {
            return CheckStreamResult.none
        }
        groups = match.values()
        return groups.count > 0 ? CheckStreamResult.match(txt) : CheckStreamResult.none
    }

    func execute(_ script: Script, _ context:ScriptContext) {
//        context.setRegexVars(self.groups)
        script.next()
    }
}
