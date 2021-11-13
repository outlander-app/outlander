//
//  GameViewController.swift
//  Outlander
//
//  Created by Joseph McBride on 12/6/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

struct Credentials {
    var account: String
    var password: String
    var character: String
    var game: String
}

class GameViewController: NSViewController, NSWindowDelegate {
    @IBOutlet var commandInput: HistoryTextField!
    @IBOutlet var gameWindowContainer: OView!
    @IBOutlet var vitalsBar: VitalsBar!
    @IBOutlet var statusBar: OView!

    var loginWindow: LoginWindow?
    var profileWindow: ProfileWindow?
    var mapWindow: MapWindow?
    var scriptRunner: ScriptRunner?

    var pluginManager = PluginManager()

    var log = LogManager.getLog(String(describing: GameViewController.self))

    var applicationSettings: ApplicationSettings? {
        didSet {
            gameContext.applicationSettings = applicationSettings!
        }
    }

    var gameWindows: [String: WindowViewController] = [:]

    var authServer: AuthenticationServer?
    var gameServer: GameServer?
    var gameStream: GameStream?
    var gameContext = GameContext()

    var credentials: Credentials?

    var windowLayoutLoader: WindowLayoutLoader?
    var fileSystem: FileSystem?

    var commandProcessor: CommandProcesssor?

    var roundtime: RoundtimeTimer?
    var spelltime: SpellTimer?
    var statusBarController: StatusBarViewController?

    var game: String = "DR"
    var character: String = ""

    private var apperanceObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        createStatusBarView()
        pluginManager.plugins.append(ExpPlugin())
        pluginManager.plugins.append(AutoMapperPlugin(context: gameContext))

//        print("Appearance Dark Mode: \(view.isDarkMode), \(view.effectiveAppearance.name)")

//        apperanceObserver = view.observe(\.effectiveAppearance) { [weak self] _, change in
//            print("Appearance changed \(change.oldValue?.name) \(change.newValue?.name)")
//            print("Main app: \(self?.view.isDarkMode), \(self?.view.effectiveAppearance.name)")
//        }

//        gameWindowContainer.backgroundColor = NSColor.blue
//        statusBar.backgroundColor = NSColor.red
//        commandInput.progress = 0.5

        roundtime = RoundtimeTimer(gameContext, variable: "roundtime")
        roundtime?.interval = { [weak self] value in
            DispatchQueue.main.async {
                self?.log.info("RT: \(value.value) / \(value.percent)")
                self?.statusBarController?.roundtime = value.value
                self?.commandInput.progress = value.percent
            }
        }

        spelltime = SpellTimer(gameContext, variable: "spelltime", initialPercent: 0.0)
        spelltime?.interval = { [weak self] value in
            DispatchQueue.main.async {
                self?.log.info("Spell RT: \(value.value) / \(value.percent)")
                var spell = "\(value.value)"
                if value.percent > 0 {
                    spell = "(\(Int(value.percent.rounded(.down)))) \(value.value)"
                }
                self?.statusBarController?.spell = spell
            }
        }

        fileSystem = LocalFileSystem(gameContext.applicationSettings)
        windowLayoutLoader = WindowLayoutLoader(fileSystem!)
        commandProcessor = CommandProcesssor(fileSystem!, pluginManager: pluginManager)
        scriptRunner = ScriptRunner(gameContext, loader: ScriptLoader(fileSystem!, settings: gameContext.applicationSettings))

        authServer = AuthenticationServer()

        gameServer = GameServer { [weak self] state in
            switch state {
            case .connected:
                self?.log.info("Connected to game server")
                self?.updateWindowTitle()
            case let .data(_, str):
                self?.handleRawStream(data: str, streamData: true)
            case .closed:
                self?.gameStream?.reset()
                self?.logText("\nDisconnected from game server\n\n")
                self?.updateWindowTitle()
            }
        }

        gameStream = GameStream(context: gameContext, streamCommands: { [weak self] command in
            switch command {
            case .text:
                break
            default:
                self?.scriptRunner?.stream("", [command])
            }

            switch command {
            case let .text(tags):
                for tag in tags {
                    self?.logTag(tag)
                    self?.scriptRunner?.stream(tag.text, [])
                }

            case let .vitals(name, value):
                self?.vitalsBar.updateValue(vital: name, text: "\(name) \(value)%".capitalized, value: value)

            case let .indicator(name, enabled):
                self?.statusBarController?.setIndicator(name: name, enabled: enabled)

            case let .hands(left, right):
                DispatchQueue.main.async {
                    self?.statusBarController?.leftHand = left
                    self?.statusBarController?.rightHand = right
                }

            case let .roundtime(date):
                let time = self?.gameContext.globalVars["gametime"] ?? ""
                let updated = self?.gameContext.globalVars["gametimeupdate"] ?? ""

                let t = date.timeIntervalSince(Date(timeIntervalSince1970: Double(time) ?? 0))
                let offset = Date().timeIntervalSince(Date(timeIntervalSince1970: Double(updated) ?? 0))

                let diff = t - offset - 0.5
                let rounded = ceil(diff)

                DispatchQueue.main.async {
                    self?.roundtime?.set(Int(rounded))
                }

            case let .clearStream(name):
                DispatchQueue.main.sync {
                    self?.clearWindow(name)
                }

            case let .createWindow(name, title, closedTarget):
                DispatchQueue.main.sync {
                    self?.maybeCreateWindow(name, title: title, closedTarget: closedTarget)
                }

            case .room:
                self?.updateRoom()

            case let .character(game, character):
                self?.game = game
                self?.character = character
                self?.updateWindowTitle()

            case let .spell(spell):
                DispatchQueue.main.async {
                    self?.spelltime?.set(spell)
                }

            case .compass:
                DispatchQueue.main.async {
                    self?.statusBarController?.avaialbleDirections = self?.gameContext.availableExits() ?? []
                }

            default:
                self?.log.warn("Unhandled command \(command)")
            }
        })

        commandInput.executeCommand = { command in
            self.commandProcessor!.process(command, with: self.gameContext)
        }

//        addWindow(WindowSettings(name: "room", visible: true, closedTarget: nil, x: 0, y: 0, height: 200, width: 800))
//        addWindow(WindowSettings(name: "main", visible: true, closedTarget: nil, x: 0, y: 200, height: 600, width: 800))
//        addWindow(WindowSettings(name: "logons", visible: true, closedTarget: nil, x: 800, y: 0, height: 200, width: 350))
//        addWindow(WindowSettings(name: "thoughts", visible: true, closedTarget: nil, x: 800, y: 200, height: 200, width: 350))
//        addWindow(WindowSettings(name: "percwindow", visible: true, closedTarget: nil, x: 800, y: 400, height: 200, width: 350))
//        addWindow(WindowSettings(name: "inv", visible: false, closedTarget: nil, x: 800, y: 600, height: 200, width: 350))

        gameContext.events.handle(self, channel: "ol:gamecommand") { result in
            guard let command = result as? Command2 else {
                return
            }

            self.logText("\(command.command)\n", playerCommand: !command.isSystemCommand)
            self.gameServer?.sendCommand(command.command)
        }

        gameContext.events.handle(self, channel: "ol:command") { result in
            guard let command = result as? Command2 else {
                return
            }

            print("processing command \(command.command)")

            self.commandProcessor?.process(command, with: self.gameContext)
        }

        gameContext.events.handle(self, channel: "ol:echo") { result in
            if let tag = result as? TextTag {
                self.logTag(tag)
            }
        }

        gameContext.events.handle(self, channel: "ol:window") { result in
            if let dict = result as? [String: String] {
                let action = dict["action"] ?? ""
                let window = dict["window"] ?? ""
                self.processWindowCommand(action, window: window)
            }
        }

        gameContext.events.handle(self, channel: "ol:text") { result in
            if let data = result as? TextData {
                self.logText(data.text, preset: data.preset, color: data.color, mono: data.mono)
            }
        }

        gameContext.events.handle(self, channel: "ol:error") { result in
            if let text = result as? String {
                self.logError(text)
            }
        }

        let indicators = ["bleeding", "stunned", "poisoned", "webbed"]

        gameContext.events.handle(self, channel: "ol:variable:changed") { result in
            if let dict = result as? [String: String] {
                for (key, value) in dict {
                    self.pluginManager.variableChanged(variable: key, value: value)

                    if key == "zoneid" || key == "roomid" {
                        self.updateRoom()
                    }

                    if indicators.contains(key) {
                        self.statusBarController?.setIndicator(name: key, enabled: value == "1")
                    }
                }
            }
        }

        gameContext.events.handle(self, channel: "ol:game:parse") { result in
            guard let data = result as? String else {
                return
            }

            self.handleRawStream(data: data, streamData: false)
        }

        gameContext.events.handle(self, channel: "ol:mapper:setpath") { result in
            if let path = result as? [String] {
                self.mapWindow?.setWalkPath(path)
            }
        }

        loginWindow = LoginWindow()
        profileWindow = ProfileWindow()
        profileWindow?.context = gameContext
        mapWindow = MapWindow()
        mapWindow?.initialize(context: gameContext)

        loadSettings()

//        commandInput.becomeFirstResponder()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        gameContext.events.unregister(self)
    }

    func windowDidBecomeKey(_: Notification) {
        registerMacros()
    }

    func windowDidResignKey(_: Notification) {
        unregisterMacros()
    }

    func registerMacros() {
//        print("registering macros")
    }

    func unregisterMacros() {
//        print("un-registering macros")
    }

    func updateWindowTitle() {
        DispatchQueue.main.async {
            if let win = self.view.window {
                let version = "2"
                let gameInfo = self.game.count > 0 ? "\(self.game)" : ""
                let charInfo = self.character.count > 0 ? "\(self.character) - " : ""
                let connection = self.gameServer?.isConnected == true ? "" : " [disconnected]"

                win.title = "\(gameInfo): \(charInfo)Outlander \(version)\(connection)"
            }
        }
    }

    func handleRawStream(data: String, streamData: Bool = false) {
        var result = data

        if data.hasPrefix("<") {
            result = pluginManager.parse(xml: data)
        } else {
            result = pluginManager.parse(text: result)
        }

        log.rawStream(result)

        if streamData {
            gameStream?.stream(result)
        } else {
            gameStream?.sendToHandlers(text: result)
        }
    }

    func showLogin() {
        loginWindow?.loadPassword()
        view.window?.beginSheet(loginWindow!.window!, completionHandler: { result in
            guard result == .OK else {
                self.loginWindow!.clearPassword()
                return
            }
            self.credentials = Credentials(
                account: self.loginWindow!.account,
                password: self.loginWindow!.password,
                character: self.loginWindow!.character,
                game: self.loginWindow!.game
            )

            self.loginWindow!.clearPassword()

            self.gameContext.applicationSettings.profile.update(with: self.credentials!)
            self.connect()
        })
    }

    func showProfileSelection() {
        view.window?.beginSheet(profileWindow!.window!, completionHandler: { result in
            guard result == .OK else {
                return
            }

            guard let profile = self.profileWindow!.selected else {
                return
            }

            self.gameContext.applicationSettings.profile.name = profile
            self.loadSettings()
        })
    }

    func showMapWindow() {
        DispatchQueue.main.async {
            self.mapWindow?.showWindow(self)
            self.mapWindow?.setSelectedZone()
        }
    }

    func loadSettings() {
        ProfileLoader(fileSystem!).load(gameContext)
        reloadWindows(gameContext.applicationSettings.profile.layout) {
            self.reloadTheme()
            self.printSettingsLocations()
            self.logText("Loaded profile \(self.gameContext.applicationSettings.profile.name)\n", mono: true, playerCommand: false)

            self.loginWindow?.account = self.gameContext.applicationSettings.profile.account
            self.loginWindow?.character = self.gameContext.applicationSettings.profile.character
            self.loginWindow?.game = self.gameContext.applicationSettings.profile.game

//            self.gameContext.events.sendCommand(Command2(command: "#mapper reload", isSystemCommand: true))
            self.pluginManager.initialize(host: LocalHost(context: self.gameContext))
            self.updateWindowTitle()
        }
    }

    func printSettingsLocations() {
        logText("Config: \(gameContext.applicationSettings.paths.config.path)\n", mono: true, playerCommand: false)
        logText("Profile: \(gameContext.applicationSettings.currentProfilePath.path)\n", mono: true, playerCommand: false)
        logText("Maps: \(gameContext.applicationSettings.paths.maps.path)\n", mono: true, playerCommand: false)
        logText("Scripts: \(gameContext.applicationSettings.paths.scripts.path)\n", mono: true, playerCommand: false)
        logText("Logs: \(gameContext.applicationSettings.paths.logs.path)\n", mono: true, playerCommand: false)
    }

    func reloadTheme() {}

    public func command(_ command: String) {
        if command == "layout:LoadDefault" {
            gameContext.applicationSettings.profile.layout = "default.cfg"
            gameContext.layout = windowLayoutLoader?.load(gameContext.applicationSettings, file: "default.cfg")
            reloadWindows("default.cfg") {
                self.reloadTheme()
            }

            return
        }

        if command == "layout:SaveDefault" {
            gameContext.applicationSettings.profile.layout = "default.cfg"
//            let layout = buildWindowsLayout()
//            windowLayoutLoader?.save(
//                applicationSettings!,
//                file: "default.cfg",
//                windows: layout
//            )

            return
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
                gameContext.applicationSettings.profile.layout = url.lastPathComponent
                gameContext.layout = windowLayoutLoader?.load(gameContext.applicationSettings, file: url.lastPathComponent)
                reloadWindows(url.lastPathComponent) {
                    self.reloadTheme()
                }
            }

            return
        }

        if command == "layout:SaveAs" {
            let savePanel = NSSavePanel()
            savePanel.message = "Choose your Outlander layout file"
            savePanel.prompt = "Choose"
            savePanel.allowedFileTypes = ["cfg"]
            savePanel.allowsOtherFileTypes = false
            savePanel.nameFieldStringValue = gameContext.applicationSettings.profile.layout
            savePanel.directoryURL = gameContext.applicationSettings.paths.layout

            if let url = savePanel.runModal() == .OK ? savePanel.url : nil {
                gameContext.applicationSettings.profile.layout = url.lastPathComponent

                let layout = buildWindowsLayout()
                for l in layout.windows {
                    print("\(l.name) \(l.order)")
                }
                windowLayoutLoader?.save(
                    applicationSettings!,
                    file: url.lastPathComponent,
                    windows: layout
                )
            }

            return
        }

        if command == "show:mapwindow" {
            showMapWindow()

            return
        }

        if command == "profile:save" {
            ApplicationLoader(fileSystem!).save(gameContext.applicationSettings.paths, context: gameContext)
            ProfileLoader(fileSystem!).save(gameContext)
            logText("settings saved\n", mono: true, playerCommand: false)

            return
        }

        log.warn("Unhandled event command \(command)")
    }

    func buildWindowsLayout() -> WindowLayout {
        let mainWindow = view.window!

        let primary = WindowData()
        primary.name = "primary"
        primary.x = Double(mainWindow.frame.maxX)
        primary.y = Double(mainWindow.frame.maxY)
        primary.height = Double(mainWindow.frame.height)
        primary.width = Double(mainWindow.frame.width)

        var windows = gameWindows.map {
            $0.value.toWindowData(order: gameWindowContainer.index(of: $0.key))
        }

        windows.sort { $0.order > $1.order }

        return WindowLayout(primary: primary, windows: windows)
    }

    public func processWindowCommand(_ action: String, window: String) {
        if action == "clear" {
            guard !window.isEmpty else {
                return
            }

            clearWindow(window)
        }

        if action == "add" {
            maybeCreateWindow(window, title: nil)
            showWindow(window)
        }

        if action == "reload" {
            reloadWindows(gameContext.applicationSettings.profile.layout) {
                self.reloadTheme()
            }
        }

        if action == "hide" {
            guard !window.isEmpty else {
                return
            }
            hideWindow(window)
        }

        if action == "show" {
            guard !window.isEmpty else {
                return
            }
            showWindow(window)
        }

        if action == "list" {
            logText("\nWindows:\n", mono: true, playerCommand: false)
            let sortedWindows = gameWindows.sorted { $0.1.visible && !$1.1.visible }
            for win in sortedWindows {
                let frame = win.value.view.frame
                let hidden = win.value.visible ? "" : "(hidden) "
                let closedTarget = win.value.closedTarget ?? ""
                let closedDisplay = closedTarget.count > 0 ? "->\(closedTarget)" : ""
                logText("    \(hidden)\(win.key)\(closedDisplay): (x:\(frame.maxX), y:\(frame.maxY)), (h:\(frame.height), w:\(frame.width))\n", mono: true, playerCommand: false)
            }

            logText("\n", playerCommand: false)
        }
    }

    @IBAction func Send(_: Any) {
        commandInput.commitHistory()
    }

    func connect() {
        guard let credentials = credentials else {
            return
        }

        let host = gameContext.applicationSettings.authenticationServerAddress
        let port = gameContext.applicationSettings.authenticationServerPort

        logText("Connecting to authentication server at \(host):\(port)\n")

        authServer?.authenticate(
            AuthInfo(
                host: gameContext.applicationSettings.authenticationServerAddress,
                port: gameContext.applicationSettings.authenticationServerPort,
                account: credentials.account,
                password: credentials.password,
                game: credentials.game,
                character: credentials.character
            ),
            callback: { [weak self] result in

                switch result {
//                case .connected:
//                    self?.logText("Connected to authentication server\n")

                case let .success(connection):
                    self?.logText("Connecting to game server at \(connection.host):\(connection.port)\n")
                    self?.gameServer?.connect(host: connection.host, port: connection.port, key: connection.key)

                case .closed:
                    self?.logText("Disconnected from authentication server\n")

                case let .error(error):
                    self?.logError("\(error)\n")

                default:
                    self?.log.info("default auth result: \(result)")
                }
            }
        )
    }

    func updateRoom() {
        if let window = gameWindows["room"] {
            let tags = gameContext.buildRoomTags()
            window.clearAndAppend(tags, highlightMonsters: true)
        }
    }

    func createStatusBarView() {
        let storyboard = NSStoryboard(name: "StatusBar", bundle: Bundle.main)
        statusBarController = storyboard.instantiateInitialController() as? StatusBarViewController
        statusBar.subviews.append(statusBarController!.view)
    }

    func removeAllWindows() {
        for (_, win) in gameWindows {
            hideWindow(win.name, withNotification: true)
        }

        gameWindows.removeAll()
    }

    func reloadWindows(_ file: String, callback: (() -> Void)? = nil) {
        if let layout = gameContext.layout {
            DispatchQueue.main.async {
                if let mainView = self.view as? OView {
                    mainView.backgroundColor = NSColor(hex: layout.primary.backgroundColor)
                }

                if let mainWindow = self.view.window {
                    mainWindow.setFrame(NSRect(
                        x: layout.primary.x,
                        y: layout.primary.y,
                        width: layout.primary.width,
                        height: layout.primary.height
                    ),
                    display: true)
                }

                self.removeAllWindows()

                for win in layout.windows {
                    self.addWindow(win)
                }

                DispatchQueue.main.async {
                    self.logText("Loaded layout \(file)\n", mono: true, playerCommand: false)
                    callback?()
                }
            }
        }
    }

    func windowFor(name: String) -> String? {
        if let window = gameWindows[name] {
            if window.visible { return name }

            if let closedTarget = window.closedTarget, closedTarget.count > 0 {
                return windowFor(name: closedTarget)
            }

            return nil
        }

        return "main"
    }

    func maybeCreateWindow(_ name: String, title: String?, closedTarget: String? = nil) {
        guard gameWindows[name] == nil else {
            gameWindows[name]?.windowTitle = title
            return
        }

        let settings = WindowData()
        settings.name = name
        settings.title = title
        settings.closedTarget = closedTarget
        settings.visible = 0
        settings.x = 0
        settings.y = 0
        settings.height = 200
        settings.width = 300

        addWindow(settings)
    }

    func clearWindow(_ name: String) {
        if let window = gameWindows[name] {
            window.clear()
        }
    }

    func addWindow(_ settings: WindowData) {
        if let window = createWindow(settings) {
            if window.visible {
                gameWindowContainer.addSubview(window.view)
            }
            gameWindows[settings.name] = window
        }
    }

    func createWindow(_ settings: WindowData) -> WindowViewController? {
        let storyboard = NSStoryboard(name: "Window", bundle: Bundle.main)
        let controller = storyboard.instantiateInitialController() as? WindowViewController

        controller?.gameContext = gameContext

        controller?.name = settings.name
        controller?.visible = settings.visible == 1
        controller?.closedTarget = settings.closedTarget
        controller?.fontName = settings.fontName
        controller?.fontSize = settings.fontSize
        controller?.monoFontName = settings.monoFontName
        controller?.monoFontSize = settings.monoFontSize
        controller?.foregroundColor = settings.fontColor
        controller?.backgroundColor = settings.backgroundColor
        controller?.borderColor = settings.borderColor
        controller?.displayBorder = settings.showBorder == 1
        controller?.displayTimestamp = settings.timestamp == 1
        controller?.bufferSize = settings.bufferSize
        controller?.bufferClearSize = settings.bufferClearSize
        controller?.location = NSRect(x: settings.x, y: settings.y, width: settings.width, height: settings.height)

        return controller
    }

    func showWindow(_ name: String) {
        if let window = gameWindows[name] {
            if !window.view.isDescendant(of: gameWindowContainer) {
                gameWindowContainer.addSubview(window.view)
            }

            window.visible = true
            // TODO: bring window to front

            logText("\(name) window opened\n")
        }
    }

    func hideWindow(_ name: String, withNotification: Bool = true) {
        if let win = gameWindows[name] {
            win.hide()
        }

        if withNotification {
            logText("\(name) window closed\n")
        }
    }

    func logText(_ text: String, preset: String? = nil, color: String? = nil, mono: Bool = false, playerCommand: Bool = false) {
        logTag(TextTag.tagFor(text, window: "main", mono: mono, color: color, preset: preset, playerCommand: playerCommand))
    }

    func logError(_ text: String) {
        logTag(TextTag(text: text, window: "main", mono: true, preset: "scripterror"))
    }

    func logTag(_ tag: TextTag) {
        if let windowName = windowFor(name: tag.window), let window = gameWindows[windowName] {
            window.append(tag)
        }
    }
}
