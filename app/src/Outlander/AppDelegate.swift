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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let bundle = Bundle(for: GameViewController.self)
        let storyboard = NSStoryboard(name: "Game", bundle: bundle)
        let controller = storyboard.instantiateInitialController() as? GameViewController
        
        window = NSWindow(
            contentRect: NSMakeRect(0, 0, NSScreen.main!.frame.midX, NSScreen.main!.frame.midY),
            styleMask: [.titled, .resizable, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window?.title = "Outlander2"
        window?.center()
        window?.isMovableByWindowBackground = true
        window?.makeKeyAndOrderFront(nil)
        
        window?.contentViewController = controller

    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}

struct AppState {
    
    var fieldText = ""
    var gameText = "this is some text"
    var showHealthBars = false
    var sendCommand: (String)->() = {c in }
    var login: ()->() = {}

    enum Message: Equatable {
        case command
        case login
        case text(String)
        case toggleHealthBars
    }

    mutating func update(_ msg: Message) -> [Command<Message>] {
        switch msg {
        case .login:
            login()
            return []

        case .command:
            let command = fieldText
            fieldText = ""
            sendCommand(command)
            return []

        case .text(let value):
//            print("field: \(value)")
            self.fieldText = value
            return []

        case .toggleHealthBars:
            print("Toggling")
            self.showHealthBars = !self.showHealthBars
            return []
        }
    }
}

extension AppState {
    var viewController: ViewController<Message> {
        let vitals: View<AppState.Message> = .stackView([
                            .vitalBarItem("health", value: 1, backgroundColor: NSColor(hex: "#cc0000")),
                            .vitalBarItem("mana", value: 1, backgroundColor: NSColor(hex: "#00004B")),
                            .vitalBarItem("stamina", value: 1, backgroundColor: NSColor(hex: "#004000")),
                            .vitalBarItem("concentration", value: 1, backgroundColor: NSColor(hex: "#009999")),
                            .vitalBarItem("spirit", value: 1, backgroundColor: NSColor(hex: "#400040"))
                        ], axis: .horizontal, distribution: .fillEqually, alignment: .top, spacing: 0)

        var views: [View<AppState.Message>] = [
            .textView(text: self.gameText),
            .textField(text: self.fieldText, onChange: {value in .text(value)}),
            .stackView([
                .button(text: "Command", onClick: .command),
                .button(text: "Login", onClick: .login)
            ], axis: .horizontal),
//            .button(text: "Toggle", onClick: .toggleHealthBars)
        ]

        if showHealthBars {
            views.insert(vitals, at: 0)
        }

        return .viewController(
            .stackView(views, axis: .vertical, distribution: .fillEqually, alignment: .top)
        )
    }
}
