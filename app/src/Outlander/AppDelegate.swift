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
    
    var authServer: AuthenticationServer?
    var gameServer: GameServer?
    var gameStream: GameStream?

    var driver: Driver<AppState, AppState.Message>?

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        var state = AppState()
        state.sendCommand = { [weak self] command in
            print("\(command)")
            self?.gameServer?.sendCommand(command)
        }

        state.login = { [weak self] in
            self?.authServer?.authenticate(
                AuthInfo(
                    host: "eaccess.play.net",
                    port: 7900,
                    account: "",
                    password: "",
                    game: "DR",
                    character: ""),
                callback: { [weak self] result in

                    switch result {
                    case .success(let connection):
                        self?.gameServer?.connect(host: connection.host, port: connection.port, key: connection.key)

                    default:
                        print("auth result: \(result)")
                    }
                }
            )
        }

        driver = Driver<AppState, AppState.Message>(
                state,
                update: { state, message in state.update(message) },
                view: { state in state.viewController })
        
        window = NSWindow(
            contentRect: NSMakeRect(0, 0, NSScreen.main!.frame.midX, NSScreen.main!.frame.midY),
            styleMask: [.titled, .resizable, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window?.title = "Outlander2"
        window?.center()
        window?.isMovableByWindowBackground = true
        window?.contentView = driver!.viewController.view
        window?.makeKeyAndOrderFront(nil)

        authServer = AuthenticationServer()
        gameServer = GameServer({ [weak self] state in
            switch state {
            case .data(_, let str):
                self?.gameStream?.stream(str)
            case .closed:
                self?.gameStream?.resetSetup()
            default:
                print("\(state)")
            }
        })
        gameStream = GameStream(context: GameContext(), streamCommands: {command in
            switch command {
            case .text(let tags):
                for tag in tags {
                    print(tag.text)
                }
            default:
                print(command)
            }
        })
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}

struct AppState {
    
    var fieldText = ""
    var showHealthBars = true
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
                        ], axis: .horizontal, distribution: .fillEqually, alignment: .bottom, spacing: 0)
        
        var views: [View<AppState.Message>] = [
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
            .stackView(views, axis: .vertical, distribution: .fillProportionally, alignment: .top)
        )
    }
}
