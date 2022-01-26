//
//  EvalCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/7/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class EvalCommandHandler: ICommandHandler {
    var command = "#eval"

    func handle(_ input: String, with context: GameContext) {
        let text = input[command.count...]

        let result = ScriptTokenizer().read("eval \(text)")

        func replaceVars(_ input: String) -> String {
            let varContext = VariableContext()
            varContext.add("$", values: { key in context.globalVars[key] })
            return VariableReplacer().replace(input, context: varContext)
        }

        switch result {
        case let .eval(variable, expression):
            let targetVar = replaceVars(variable)
            let result = FunctionEvaluator(context, replaceVars).evaluateStrValue(expression)
            context.globalVars[targetVar] = result.result
        default:
            context.events2.echoError("Unable to parse input for #eval: \(text)")
        }
    }
}
