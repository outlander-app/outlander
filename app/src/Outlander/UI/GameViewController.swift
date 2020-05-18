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

    var log = LogManager.getLog(String(describing: GameViewController.self))

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
    
    var windowLayoutLoader: WindowLayoutLoader?
    var fileSystem: FileSystem?
    
    var commandProcessor:CommandProcesssor?
    
    var roundtime: IntervalTimer?
    var spelltime: IntervalTimer?

    override func viewDidLoad() {

        accountInput.stringValue = ""
        characterInput.stringValue = ""
        passwordInput.stringValue = ""

        self.roundtime = IntervalTimer(self.gameContext, variable: "roundtime")
        self.roundtime?.interval = {[weak self]value in
            DispatchQueue.main.async {
                self?.log.info("RT: \(value.value) / \(value.percent)")
                self?.commandInput.progress = value.percent
            }
        }

        // TODO: this needs to tick up not down
        self.spelltime = IntervalTimer(self.gameContext, variable: "spelltime")
        self.spelltime?.interval = {[weak self]value in
            DispatchQueue.main.async {
                self?.log.info("Spell RT: \(value.value) / \(value.percent)")
            }
        }

        self.fileSystem = LocalFileSystem(self.gameContext.applicationSettings)
        self.windowLayoutLoader = WindowLayoutLoader(self.fileSystem!)
        self.commandProcessor = CommandProcesssor(self.fileSystem!)

        authServer = AuthenticationServer()

        gameServer = GameServer({ [weak self] state in
            switch state {
            case .data(_, let str):
                self?.log.rawStream(str)
                self?.gameStream?.stream(str)
            case .closed:
                self?.gameStream?.resetSetup()
                self?.logText("\nDisconnected from game server\n\n")
            default:
                self?.log.info("\(state)")
            }
        })

        gameStream = GameStream(context: self.gameContext, streamCommands: {[weak self] command in
            switch command {
            case .text(let tags):
                for tag in tags {
                    self?.logTag(tag)
                }

            case .vitals(let name, let value):
                self?.vitalsBar.updateValue(vital: name, text: "\(name) \(value)%".capitalized, value: value)

            case .roundtime(let date):
                let time = self?.gameContext.globalVars["gametime"] ?? ""
                let updated = self?.gameContext.globalVars["gametimeupdate"] ?? ""

                let t = date.timeIntervalSince(Date(timeIntervalSince1970: Double(time) ?? 0))
                let offset = Date().timeIntervalSince(Date(timeIntervalSince1970: Double(updated) ?? 0))

                let diff = t - offset - 0.5
                let rounded = ceil(diff)

                DispatchQueue.main.async {
                    self?.roundtime?.set(value: Int(rounded))
                }

            case .clearStream(let name):
                self?.clearWindow(name)

            case .createWindow(let name, _, _):
                self?.maybeCreateWindow(name)

            case .room:
                self?.updateRoom()

            case .character(let game, let character):
                DispatchQueue.main.async {
                    if let win = self?.view.window {
                        win.title = "\(game): \(character) - Outlander 2"
                    }
                }

            default:
                self?.log.warn("\(command)")
            }
        })

        self.commandInput.executeCommand = {command in
            self.commandProcessor!.process(command, with: self.gameContext)
        }

        self.commandInput.becomeFirstResponder()

//        addWindow(WindowSettings(name: "room", visible: true, closedTarget: nil, x: 0, y: 0, height: 200, width: 800))
//        addWindow(WindowSettings(name: "main", visible: true, closedTarget: nil, x: 0, y: 200, height: 600, width: 800))
//        addWindow(WindowSettings(name: "logons", visible: true, closedTarget: nil, x: 800, y: 0, height: 200, width: 350))
//        addWindow(WindowSettings(name: "thoughts", visible: true, closedTarget: nil, x: 800, y: 200, height: 200, width: 350))
//        addWindow(WindowSettings(name: "percwindow", visible: true, closedTarget: nil, x: 800, y: 400, height: 200, width: 350))
//        addWindow(WindowSettings(name: "inv", visible: false, closedTarget: nil, x: 800, y: 600, height: 200, width: 350))

        self.gameContext.events.handle(self, channel: "ol:gamecommand") { result in
            guard let command = result as? Command2 else {
                return
            }

            self.logText("\(command.command)\n", playerCommand: !command.isSystemCommand)
            self.gameServer?.sendCommand(command.command)
        }
        
        self.gameContext.events.handle(self, channel: "ol:command") { result in
            guard let command = result as? Command2 else {
                return
            }
            
            self.commandProcessor?.process(command, with: self.gameContext)
        }

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

        self.gameContext.events.handle(self, channel: "ol:text") { result in
            if let text = result as? String {
                self.logText(text)
            }
        }

        self.gameContext.events.handle(self, channel: "ol:error") { result in
            if let text = result as? String {
                self.logError(text)
            }
        }

        self.loadSettings()
        self.reloadWindows(self.gameContext.applicationSettings.profile.layout)

        self.accountInput.stringValue = self.gameContext.applicationSettings.profile.account
        self.characterInput.stringValue = self.gameContext.applicationSettings.profile.character
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        self.gameContext.events.unregister(self)
    }

    func loadSettings() {
        ProfileLoader(self.fileSystem!).load(self.gameContext)
    }

    public func command(_ command: String) {

        if command == "layout:LoadDefault" {
            self.gameContext.applicationSettings.profile.layout = "default.cfg"
            self.gameContext.layout = self.windowLayoutLoader?.load(self.gameContext.applicationSettings, file: "default.cfg")
            self.reloadWindows("default.cfg")
        }

        if command == "layout:SaveDefault" {
            self.gameContext.applicationSettings.profile.layout = "default.cfg"
            let layout = buildWindowsLayout()
            self.windowLayoutLoader?.save(
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
                self.gameContext.applicationSettings.profile.layout = url.lastPathComponent
                // TODO: reload theme
                self.gameContext.layout = self.windowLayoutLoader?.load(self.gameContext.applicationSettings, file: url.lastPathComponent)
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
                self.gameContext.applicationSettings.profile.layout = url.lastPathComponent

                let layout = buildWindowsLayout()
                self.windowLayoutLoader?.save(
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
                    self?.log.info("auth result: \(result)")
                }
            }
        )
    }

    func updateRoom() {
        if let window = self.gameWindows["room"] {
            let tags = self.gameContext.buildRoomTags()
            window.clearAndAppend(tags, highlightMonsters: true)
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
