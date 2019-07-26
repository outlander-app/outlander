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
    var showHealthBars = true
    
    enum Message: Equatable {
        case clicked
        case text(String)
        case toggleHealthBars
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
                        ], axis: .horizontal, distribution: .fillEqually, alignment: .bottom, spacing: 0)
        
        var views: [View<AppState.Message>] = [
            .textField(text: self.fieldText, onChange: {value in .text(value)}),
            .stackView([
                .button(text: "Cancel", onClick: .clicked),
                .button(text: "Connect", onClick: .clicked)
            ], axis: .horizontal),
            .button(text: "Toggle", onClick: .toggleHealthBars)
        ]

        if showHealthBars {
            views.insert(vitals, at: 0)
        }
        
        return .viewController(
            .stackView(views, axis: .vertical, distribution: .fillProportionally, alignment: .top)
        )
    }
}
