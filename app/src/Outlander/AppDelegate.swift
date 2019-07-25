//
//  AppDelegate.swift
//  Outlander
//
//  Created by Joseph McBride on 7/18/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow?

    let driver = Driver<AppState, AppState.Message>(
        AppState(),
        update: { state, message in state.update(message) },
        view: { state in state.viewController })
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window = NSWindow(
            contentRect: NSMakeRect(0, 0, NSScreen.main!.frame.midX, NSScreen.main!.frame.midY),
            styleMask: [.titled, .resizable, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window?.title = "Outlander2"
        window?.center()
        window?.isMovableByWindowBackground = true
        window?.contentView = driver.viewController.view
        window?.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}

struct AppState {
    
    var fieldText = "testing"
    
    enum Message: Equatable {
        case clicked
        case text(String)
    }

    mutating func update(_ msg: Message) -> [Command<Message>] {
        switch msg {
        case .clicked:
            print("clicked! \(fieldText)")
            return []

        case .text(let value):
            print("field: \(value)")
            self.fieldText = value
            return []
        }
    }
}

extension AppState {
    var viewController: ViewController<Message> {
        return .viewController(
            .stackView([
                .textField(text: self.fieldText, onChange: {value in .text(value)}),
                .stackView([
                    .button(text: "Cancel", onClick: .clicked),
                    .button(text: "Connect", onClick: .clicked)
                ], axis: .horizontal),
            ], axis: .vertical)
        )
    }
}
