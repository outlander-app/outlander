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

    var applicationSettings:ApplicationSettings? {
        didSet {
            self.gameContext.applicationSettings = self.applicationSettings!
        }
    }
    
    var gameWindows:[String:WindowViewController] = [:]

    var authServer: AuthenticationServer?
    var gameServer: GameServer?
    var gameStream: GameStream?
    var gameContext = GameContext()
    
    let windowLayoutLoader = WindowLayoutLoader()
    
    var commandHandler = CommandHandlerProcesssor()

    override func viewDidLoad() {

        accountInput.stringValue = ""
        characterInput.stringValue = ""
        passwordInput.stringValue = ""

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

            case .character(let game, let character):
                DispatchQueue.main.async {
                    if let win = self.view.window {
                        win.title = "\(game): \(character) - Outlander 2"
                    }
                }

            default:
                print(command)
            }
        })

        self.commandInput.executeCommand = {command in
            guard !self.commandHandler.handled(command: command, withContext: self.gameContext) else {
                return
            }

            self.logText("\(command)\n", playerCommand: true)

            self.gameServer?.sendCommand(command)
        }

        self.commandInput.becomeFirstResponder()
        self.reloadWindows("default.cfg")

//        addWindow(WindowSettings(name: "room", visible: true, closedTarget: nil, x: 0, y: 0, height: 200, width: 800))
//        addWindow(WindowSettings(name: "main", visible: true, closedTarget: nil, x: 0, y: 200, height: 600, width: 800))
//        addWindow(WindowSettings(name: "logons", visible: true, closedTarget: nil, x: 800, y: 0, height: 200, width: 350))
//        addWindow(WindowSettings(name: "thoughts", visible: true, closedTarget: nil, x: 800, y: 200, height: 200, width: 350))
//        addWindow(WindowSettings(name: "percwindow", visible: true, closedTarget: nil, x: 800, y: 400, height: 200, width: 350))
//        addWindow(WindowSettings(name: "inv", visible: false, closedTarget: nil, x: 800, y: 600, height: 200, width: 350))

        self.gameContext.events.handle(self, channel: "ol:echo") { result in
            if let tag = result as? TextTag {
                self.logTag(tag)
            }
        }

        self.gameContext.events.handle(self, channel: "ol:window") { result in
            if let dict = result as? [String:String] {
                let action = dict["action"] ?? ""
                let window = dict["window"] ?? ""
                self.processWindowCommand(action, window: window)
            }
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.gameContext.events.unregister(self)
    }

    public func command(_ command: String) {
        print("command: \(command)")

        if command == "layout:LoadDefault" {
            self.reloadWindows("default.cfg")
        }
        
        if command == "layout:SaveDefault" {
            let layout = buildWindowsLayout()
            self.windowLayoutLoader.save(
                self.applicationSettings!,
                file: "default.cfg",
                windows: layout
            )
        }
        
        if command == "layout:Load" {
            let openPanel = NSOpenPanel()
            openPanel.message = "Choose your Outlander layout file"
            openPanel.prompt = "Choose"
            openPanel.allowedFileTypes = ["cfg"]
            openPanel.allowsMultipleSelection = false
            openPanel.allowsOtherFileTypes = false
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false

            if let url = openPanel.runModal() == .OK ? openPanel.urls.first : nil {
                // TODO: reload theme
                self.removeAllWindows()
                self.reloadWindows(url.lastPathComponent)
            }
        }

        if command == "layout:SaveAs" {
            let openPanel = NSOpenPanel()
            openPanel.message = "Choose your Outlander layout file"
            openPanel.prompt = "Choose"
            openPanel.allowedFileTypes = ["cfg"]
            openPanel.allowsMultipleSelection = false
            openPanel.allowsOtherFileTypes = false
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
            
            if let url = openPanel.runModal() == .OK ? openPanel.urls.first : nil {
                let layout = buildWindowsLayout()
                self.windowLayoutLoader.save(
                    self.applicationSettings!,
                    file: url.lastPathComponent,
                    windows: layout
                )
            }
        }
    }

    func buildWindowsLayout() -> WindowLayout {
        
        let mainWindow = self.view.window!

        let primary = WindowData()
        primary.x = Double(mainWindow.frame.maxX)
        primary.y = Double(mainWindow.frame.maxY)
        primary.height = Double(mainWindow.frame.height)
        primary.width = Double(mainWindow.frame.width)
        
        let windows = [WindowData()]

        return WindowLayout(primary: primary, windows: windows)
    }

    public func processWindowCommand(_ action: String, window: String) {
        
        if action == "clear" {
            guard !window.isEmpty else {
                return
            }
            
            self.clearWindow(window)
        }
        
        if action == "add" {
        }

        if action == "reload" {
            // TODO: reload theme
            self.removeAllWindows()
            self.reloadWindows("default.cfg")
        }
        
        if action == "hide" {
            guard !window.isEmpty else {
                return
            }
            self.hideWindow(window)
        }
        
        if action == "show" {
            guard !window.isEmpty else {
                return
            }
            self.showWindow(window)
        }

        if action == "list" {
            self.logText("\nWindows:\n", mono: true, playerCommand: false)
            let sortedWindows = self.gameWindows.sorted { ($0.1.visible && !$1.1.visible) }
            for win in sortedWindows {
                let frame = win.value.view.frame
                let hidden = win.value.visible ? "" : "(hidden) "
                let closedTarget = win.value.closedTarget ?? ""
                let closedDisplay = closedTarget.count > 0 ? "->\(closedTarget)" : ""
                self.logText("    \(hidden)\(win.key)\(closedDisplay): (x:\(frame.maxX), y:\(frame.maxY)), (h:\(frame.height), w:\(frame.width))\n", mono: true, playerCommand: false)
            }
            
            self.logText("\n", playerCommand: false)
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

                case .closed:
                    self?.logText("Disconnected from authentication server\n")

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
    
    func removeAllWindows() {
        for (_, win) in self.gameWindows {
            self.hideWindow(win.name, withNotification: true)
        }
        
        self.gameWindows.removeAll()
    }

    func reloadWindows(_ file:String) {
        if let layout = self.gameContext.layout {
            DispatchQueue.main.async {
                if let mainView = self.view as? OView {
                    mainView.backgroundColor = NSColor(hex: layout.primary.backgroundColor)
                }

                if let mainWindow = self.view.window {
                    mainWindow.setFrame(NSRect(
                        x: layout.primary.x,
                        y: layout.primary.y,
                        width: layout.primary.width,
                        height: layout.primary.height),
                                 display: true)
                }

                for win in layout.windows {
                    self.addWindow(win)
                }

                DispatchQueue.main.async {
                    self.logText("Loaded layout \(file)\n", mono: true, playerCommand: false)
                }
            }
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
        
        let settings = WindowData()
        settings.name = name
        settings.visible = 0
        settings.x = 0
        settings.y = 0
        settings.height = 200
        settings.width = 200
        
        self.addWindow(settings)
    }

    func clearWindow(_ name: String) {
        if let window = self.gameWindows[name] {
            window.clear()
        }
    }

    func addWindow(_ settings: WindowData) {
        DispatchQueue.main.async {
            if let window = self.createWindow(settings) {
                if window.visible {
                    self.gameWindowContainer.addSubview(window.view)
                }
                self.gameWindows[settings.name] = window
            }
        }
    }

    func createWindow(_ settings: WindowData) -> WindowViewController? {
        let storyboard = NSStoryboard(name: "Window", bundle: Bundle.main)
        let controller = storyboard.instantiateInitialController() as? WindowViewController
        
        controller?.gameContext = self.gameContext

        controller?.name = settings.name
        controller?.visible = settings.visible == 1
        controller?.closedTarget = settings.closedTarget
        controller?.foregroundColor = settings.fontColor
        controller?.backgroundColor = settings.backgroundColor
        controller?.borderColor = settings.borderColor

        controller?.view.setFrameSize(NSSize(width: settings.width, height: settings.height))
        controller?.view.setFrameOrigin(NSPoint(x: settings.x, y: settings.y))

        return controller
    }

    func showWindow(_ name: String) {
        DispatchQueue.main.async {
            if let window = self.gameWindows[name] {

                if !window.view.isDescendant(of: self.gameWindowContainer) {
                    self.gameWindowContainer.addSubview(window.view)
                }
    
                window.visible = true
                // TODO: bring window to front
            }
        }
    }
    
    func hideWindow(_ name: String, withNotification:Bool = true) {
        if let win = self.gameWindows[name] {
            win.view.removeFromSuperview()
            win.visible = false
        }
    
        if withNotification {
            self.logText("\(name) window closed\n")
        }
    }

    func logText(_ text: String, mono: Bool = false, playerCommand: Bool = false) {
        logTag(TextTag(text: text, window: "main", mono: mono, playerCommand: playerCommand))
    }

    func logError(_ text: String) {
        logTag(TextTag(text: text, window: "main", mono: true, preset: "scripterror"))
    }

    func logTag(_ tag: TextTag) {
        if let windowName = windowFor(name: tag.window), let window = self.gameWindows[windowName] {
            window.append(tag)
        }
    }
}
