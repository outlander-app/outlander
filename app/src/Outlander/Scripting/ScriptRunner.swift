//
//  ScriptRunner.swift
//  Outlander
//
//  Created by Joe McBride on 2/19/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class ScriptRunner {
    private var context: GameContext
    private var loader: IScriptLoader

    private var scripts: [Script] = []

    init(_ context: GameContext, loader: IScriptLoader) {
        self.context = context
        self.loader = loader

        self.context.events.handle(self, channel: "ol:runscript") { result in
            guard let scriptName = result as? String else {
                return
            }

            self.run(scriptName)
        }

        self.context.events.handle(self, channel: "ol:script") { result in
            guard let commands = result as? String else {
                return
            }

            context.events.echoText("script command: \(commands)")
        }
    }

    private func run(_ scriptName: String) {
        do {
            let script = try Script(scriptName, loader: loader, gameContext: context)
            self.scripts.append(script)
            script.run([])
        }
        catch {
            self.context.events.echoError("Error occurred running script \(scriptName)")
        }
    }
}
