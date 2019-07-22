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
            styleMask: [.fullSizeContentView, .titled, .resizable, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window?.title = "New Window"
        //window?.isOpaque = false
        window?.center()
        window?.isMovableByWindowBackground = true
//        window?.backgroundColor = NSColor(calibratedHue: 0, saturation: 1.0, brightness: 0, alpha: 0.7)
        window?.makeKeyAndOrderFront(nil)
//        window?.contentViewController = driver.viewController
        window?.contentView = driver.viewController.view
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}

struct AppState {
    enum Message: Equatable {
        case clicked
    }

    mutating func update(_ msg: Message) -> [Command<Message>] {
        switch msg {
        case .clicked:
            print("clicked!")
            return []
        }
    }
}

extension AppState {
    var viewController: ViewController<Message> {
        return .viewController(.button(text: "click me", onClick: .clicked))
    }
}
