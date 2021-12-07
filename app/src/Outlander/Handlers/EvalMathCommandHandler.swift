//
//  EvalMathCommandHandler.swift
//  Outlander
//
//  Created by Joe McBride on 12/7/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class EvalMathCommandHandler: ICommandHandler {
    var command = "#evalmath"

    func handle(_ input: String, with context: GameContext) {
        let text = input[command.count...]

        let result = ScriptTokenizer().read("evalmath \(text)")

        func replaceVars(_ input: String) -> String {
            let varContext = VariableContext()
            varContext.add("$", values: { key in context.globalVars[key] })
            return VariableReplacer().replace(input, context: varContext)
        }

        switch result {
        case let .evalMath(variable, expression):
            let targetVar = replaceVars(variable)
            let result = FunctionEvaluator(replaceVars).evaluateValue(expression)
            context.globalVars[targetVar] = result.result
        default:
            context.events.echoError("Unable to parse input for #evalmath: \(text)")
        }
    }
}
