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
    
    var gameWindows:[String:WindowViewController] = [:]
    
    var authServer: AuthenticationServer?
    var gameServer: GameServer?
    var gameStream: GameStream?
    var gameContext = GameContext()
    
    override func viewDidLoad() {
        
        accountInput.stringValue = ""
        characterInput.stringValue = ""
        
        gameWindowContainer.backgroundColor = NSColor.blue
        
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
            default:
                print(command)
            }
        })

        let main = WindowSettings(name: "main", closedTarget: nil, x: 0, y: 0, height: 600, width: 800)
        addWindow(main)
        
        let logons = WindowSettings(name: "logons", closedTarget: nil, x: 800, y: 0, height: 200, width: 300)
        addWindow(logons)
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

        self.logText("Connecting to authentication server at \(authHost):\(authPort) ...\n")

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
                case .success(let connection):
                    self?.logText("Connecting to game server at \(connection.host):\(connection.port) ...\n")
                    self?.gameServer?.connect(host: connection.host, port: connection.port, key: connection.key)

                default:
                    self?.logText("auth result: \(result)\n")
                }
            }
        )
    }

    func windowFor(name: String) -> String? {
        if name == "inv" { return nil }
        if name == "logons" { return "logons" }

        return "main"
    }

    func addWindow(_ settings: WindowSettings) {
        if let window = createWindow(settings) {
            self.gameWindowContainer.addSubview(window.view)
            self.gameWindows[settings.name] = window
        }
    }

    func createWindow(_ settings: WindowSettings) -> WindowViewController? {
        let storyboard = NSStoryboard(name: "Window", bundle: Bundle.main)
        let controller = storyboard.instantiateController(withIdentifier: "Window") as? WindowViewController

        controller?.name = settings.name
        controller?.gameContext = self.gameContext

        controller?.view.setFrameSize(NSSize(width: settings.width, height: settings.height))
        controller?.view.setFrameOrigin(NSPoint(x: settings.x, y: settings.y))

        return controller
    }

    func logText(_ text: String) {
        logTag(TextTag(text: text, window: "main"))
    }

    func logTag(_ tag: TextTag) {
        if let windowName = windowFor(name: tag.window), let window = self.gameWindows[windowName] {
            window.append(tag)
        }
    }
}
