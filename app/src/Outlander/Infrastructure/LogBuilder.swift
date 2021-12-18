//
//  LogBuilder.swift
//  Outlander
//
//  Created by Joe McBride on 12/17/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class LogBuilder {
    private var lock = NSLock()
    private var logText = ""
    private var lastTag: TextTag?

    func append(_ tag: TextTag, windowName: String, context: GameContext) {
        guard context.applicationSettings.profile.logging, context.applicationSettings.windowsToLog.contains(windowName) else {
            return
        }
        lock.lock()
        defer { lock.unlock() }

        if tag.text == "\n" {
            if !logText.hasSuffix("\n") {
                logText += tag.text
            }
        } else {
            if lastTag?.isPrompt == true, !tag.playerCommand {
                // skip multiple prompts of the same type
                if tag.isPrompt, lastTag?.text == tag.text {
                    return
                }

                // previous was a prompt, but this was not a player command, so add a newline
                logText += "\n"
            }

            logText += tag.text
        }

        lastTag = tag
    }

    func flush(_ log: ILogger?) {
        guard let log = log else { return }
        lock.lock()
        defer { lock.unlock() }

        guard !logText.isEmpty else {
            return
        }

        log.stream(logText)
        logText = ""
    }
}
