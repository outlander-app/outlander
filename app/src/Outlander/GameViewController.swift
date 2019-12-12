//
//  GameViewController.swift
//  Outlander
//
//  Created by Joseph McBride on 12/6/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa

class GameViewController : NSViewController {

    @IBOutlet weak var commandInput: NSTextField!
    @IBOutlet weak var accountInput: NSTextField!
    @IBOutlet weak var passwordInput: NSSecureTextField!
    @IBOutlet weak var characterInput: NSTextField!
    @IBOutlet weak var gameWindowContainer: OView!
    @IBOutlet weak var vitalsBar: VitalsBar!
    
    var gameWindows:[String:WindowViewController] = [:]

    var authServer: AuthenticationServer?
    var gameServer: GameServer?
    var gameStream: GameStream?
    var gameContext = GameContext()

    override func viewDidLoad() {

        accountInput.stringValue = ""
        characterInput.stringValue = ""
        
//        gameWindowContainer.backgroundColor = NSColor.blue
        
        authServer = AuthenticationServer()
        
        gameServer = GameServer({ [weak self] state in
            switch state {
            case .data(_, let str):
                print(str)
                self?.gameStream?.stream(str)
            case .closed:
                self?.gameStream?.resetSetup()
                self?.logText("Disconnected from game server\n\n")
            default:
                print("\(state)")
            }
        })

        gameStream = GameStream(context: self.gameContext, streamCommands: {command in
            switch command {
            case .text(let tags):
                for tag in tags {
                    self.logTag(tag)
                }

            case .vitals(let name, let value):
                self.vitalsBar.updateValue(vital: name, text: "\(name) \(value)%", value: value)
    
            default:
                print(command)
            }
        })

        addWindow(WindowSettings(name: "main", visible: true, closedTarget: nil, x: 0, y: 0, height: 600, width: 800))
        addWindow(WindowSettings(name: "logons", visible: true, closedTarget: nil, x: 800, y: 0, height: 200, width: 350))
        addWindow(WindowSettings(name: "thoughts", visible: true, closedTarget: nil, x: 800, y: 200, height: 200, width: 350))
        addWindow(WindowSettings(name: "inv", visible: false, closedTarget: nil, x: 800, y: 400, height: 200, width: 350))
    }

    @IBAction func Send(_ sender: Any) {
        let command = self.commandInput.stringValue
        if command.count == 0 { return }
        
        self.commandInput.stringValue = ""
        self.logText("\(command)\n")
        self.gameServer?.sendCommand(command)
    }
    
    @IBAction func Login(_ sender: Any) {

        let account = accountInput.stringValue
        let password = passwordInput.stringValue
        let character = characterInput.stringValue

        let authHost = "eaccess.play.net"
        let authPort:UInt16 = 7900

        self.logText("Connecting to authentication server at \(authHost):\(authPort)\n")

        self.authServer?.authenticate(
            AuthInfo(
                host: authHost,
                port: authPort,
                account: account,
                password: password,
                game: "DR",
                character: character),
            callback: { [weak self] result in

                switch result {
//                case .connected:
//                    self?.logText("Connected to authentication server\n")

                case .success(let connection):
                    self?.logText("Connecting to game server at \(connection.host):\(connection.port)\n")
                    self?.gameServer?.connect(host: connection.host, port: connection.port, key: connection.key)

//                case .closed:
//                    self?.logText("Authentication connection closed\n")

                case .error(let error):
                    self?.logError("\(error)\n")

                default:
                    print("auth result: \(result)")
                }
            }
        )
    }

    func windowFor(name: String) -> String? {
        
//        guard name.count > 0 else {
//            return nil
//        }

        if let window = self.gameWindows[name] {
            if window.visible { return name }
            
            if let closedTarget = window.closedTarget, closedTarget.count > 0 {
                return windowFor(name: closedTarget)
            }

            return nil
        }
        
        return "main"
    }

    func addWindow(_ settings: WindowSettings) {
        if let window = createWindow(settings) {
            if window.visible {
                self.gameWindowContainer.addSubview(window.view)
            }
            self.gameWindows[settings.name] = window
        }
    }

    func createWindow(_ settings: WindowSettings) -> WindowViewController? {
        let storyboard = NSStoryboard(name: "Window", bundle: Bundle.main)
        let controller = storyboard.instantiateInitialController() as? WindowViewController
        
        controller?.gameContext = self.gameContext

        controller?.name = settings.name
        controller?.visible = settings.visible
        controller?.closedTarget = settings.closedTarget

        controller?.view.setFrameSize(NSSize(width: settings.width, height: settings.height))
        controller?.view.setFrameOrigin(NSPoint(x: settings.x, y: settings.y))

        return controller
    }

    func logText(_ text: String) {
        logTag(TextTag(text: text, window: "main"))
    }

    func logError(_ text: String) {
        logTag(TextTag(text: text, window: "main"))
    }

    func logTag(_ tag: TextTag) {
        if let windowName = windowFor(name: tag.window), let window = self.gameWindows[windowName] {
            window.append(tag)
        }
    }
}
