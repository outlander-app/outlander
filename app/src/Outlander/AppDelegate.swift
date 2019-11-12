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

        var views = [
            OView(color: NSColor.red, frame: NSRect(x: 0, y: 0, width: 100, height: 100)),
//            OView(color: NSColor.blue, frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        ]
        
        let subViews = [
            OView(color: NSColor.green, frame: NSRect(x: 0, y: 0, width: 100, height: 100)),
            OView(color: NSColor.yellow, frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        ]

        let subStacker = MyStackView()
        subStacker.orientation = .horizontal
        subStacker.backgroundColor = NSColor.magenta
        for view in subViews {
            subStacker.append(view)
        }

        let stacker = MyStackView()
        stacker.orientation = .vertical
//        stacker.autoresizesSubviews = true
//        stacker.translatesAutoresizingMaskIntoConstraints = false
//        stacker.orientation = .vertical
//        stacker.alignment = .top
//        stacker.distribution = .equalSpacing
        stacker.backgroundColor = NSColor.purple

        views.append(subStacker)

        for view in views {
            stacker.append(view)
        }

        let baseView = OView(color: NSColor.green, frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        baseView.autoresizesSubviews = true
        baseView.addSubview(stacker)
        
        window = NSWindow(
            contentRect: NSMakeRect(0, 0, NSScreen.main!.frame.midX, NSScreen.main!.frame.midY),
            styleMask: [.titled, .resizable, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window?.title = "Outlander2"
        window?.center()
        window?.isMovableByWindowBackground = true
        window?.contentView = driver!.viewController.view
//        window?.contentView = stacker
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
                    print(tag.text, terminator: "")
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
