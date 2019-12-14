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

    @IBOutlet weak var commandInput: HistoryTextField!
    @IBOutlet weak var accountInput: NSTextField!
    @IBOutlet weak var passwordInput: NSSecureTextField!
    @IBOutlet weak var characterInput: NSTextField!
    @IBOutlet weak var gameWindowContainer: OView!
    @IBOutlet weak var vitalsBar: VitalsBar!

    var applicationSettings:ApplicationSettings?
    
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
                self?.logText("\nDisconnected from game server\n\n")
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
                self.vitalsBar.updateValue(vital: name, text: "\(name) \(value)%".capitalized, value: value)
                
            case .clearStream(let name):
                self.clearWindow(name)

            case .createWindow(let name, _, _):
                self.maybeCreateWindow(name)

            case .room:
                self.updateRoom()

            default:
                print(command)
            }
        })

        self.commandInput.executeCommand = {command in
            self.logText("\(command)\n", playerCommand: true)
            self.gameServer?.sendCommand(command)
        }
        
        self.commandInput.becomeFirstResponder()

        addWindow(WindowSettings(name: "room", visible: true, closedTarget: nil, x: 0, y: 0, height: 200, width: 800))
        addWindow(WindowSettings(name: "main", visible: true, closedTarget: nil, x: 0, y: 200, height: 600, width: 800))
        addWindow(WindowSettings(name: "logons", visible: true, closedTarget: nil, x: 800, y: 0, height: 200, width: 350))
        addWindow(WindowSettings(name: "thoughts", visible: true, closedTarget: nil, x: 800, y: 200, height: 200, width: 350))
        addWindow(WindowSettings(name: "percwindow", visible: true, closedTarget: nil, x: 800, y: 400, height: 200, width: 350))
        addWindow(WindowSettings(name: "inv", visible: false, closedTarget: nil, x: 800, y: 600, height: 200, width: 350))
    }

    public func command(_ command: String) {
        print("command: \(command)")

        if command == "layout:LoadDefault" {
            if let layout = WindowLayoutLoader().load(self.applicationSettings!, file: "default.cfg") {
                print("yep")
            }
        }
    }

    @IBAction func Send(_ sender: Any) {
        self.commandInput.commitHistory()
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

    func updateRoom() {
        let name = self.gameContext.globalVars["roomtitle"]
        let desc = self.gameContext.globalVars["roomdesc"]
        let objects = self.gameContext.globalVars["roomobjs"]
        let players = self.gameContext.globalVars["roomplayers"]
        let exits = self.gameContext.globalVars["roomexits"]

        var tags:[TextTag] = []
        var room = ""
        
        if name != nil && name?.count ?? 0 > 0 {
            let tag = TextTag.tagFor(name!, preset: "roomname")
            tags.append(tag)
            room += "\n"
        }

        if desc != nil && desc?.count ?? 0 > 0 {
            let tag = TextTag.tagFor("\(room)\(desc!)\n", preset: "roomdesc")
            tags.append(tag)
            room = ""
        }

        if objects != nil && objects?.count ?? 0 > 0 {
            room += "\(objects!)\n"
        }
        
        if players != nil && players?.count ?? 0 > 0 {
            room += "\(players!)\n"
        }

        if exits != nil && exits?.count ?? 0 > 0 {
            room += "\(exits!)\n"
        }

        tags.append(TextTag.tagFor(room))

        if let window = self.gameWindows["room"] {
            window.clearAndAppend(tags)
        }
    }

    func windowFor(name: String) -> String? {
        if let window = self.gameWindows[name] {
            if window.visible { return name }
            
            if let closedTarget = window.closedTarget, closedTarget.count > 0 {
                return windowFor(name: closedTarget)
            }

            return nil
        }
        
        return "main"
    }

    func maybeCreateWindow(_ name: String) {
        guard self.gameWindows[name] == nil else {
            return
        }

        self.addWindow(WindowSettings(name: name, visible: false, closedTarget: nil, x: 0, y: 0, height: 200, width: 200))
    }

    func clearWindow(_ name: String) {
        if let window = self.gameWindows[name] {
            window.clear()
        }
    }

    func addWindow(_ settings: WindowSettings) {
        DispatchQueue.main.async {
            if let window = self.createWindow(settings) {
                if window.visible {
                    self.gameWindowContainer.addSubview(window.view)
                }
                self.gameWindows[settings.name] = window
            }
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

    func logText(_ text: String, playerCommand: Bool = false) {
        logTag(TextTag(text: text, window: "main", playerCommand: playerCommand))
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
