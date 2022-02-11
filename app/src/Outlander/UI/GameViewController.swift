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
    @IBOutlet var scriptBar: OView!
    @IBOutlet var vitalsBar: VitalsBar!
    @IBOutlet var statusBar: OView!

    var loginWindow: LoginWindow?
    var profileWindow: ProfileWindow?
    var mapWindow: MapWindow?
    var scriptRunner: ScriptRunner?

    var pluginManager: PluginManager?

    var log = LogManager.getLog(String(describing: GameViewController.self))
    var gameLog: ILogger?

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

    var scriptToolbarController: ScriptToolbarViewController?
    var statusBarController: StatusBarViewController?

    var shouldUpdateRoom: Bool = false

    private var apperanceObserver: NSKeyValueObservation?

    func setGameLogger() {
        let formatter = DateFormatter()
        formatter.dateFormat = gameContext.applicationSettings.variableDateFormat
        let date = formatter.string(from: Date())
        var name = gameContext.globalVars["charactername"] ?? ""
        if name.isEmpty {
            name = gameContext.applicationSettings.profile.name
        }
        var game = gameContext.globalVars["game"] ?? ""
        if game.isEmpty {
            game = gameContext.applicationSettings.profile.game
        }
        let logFileName = "\(name)-\(game)-\(date).txt"
        gameLog = FileLogger(logFileName, root: gameContext.applicationSettings.paths.logs, files: fileSystem!)
    }

    override func viewDidLoad() {
        fileSystem = LocalFileSystem(gameContext.applicationSettings)
        setGameLogger()

        createScriptToolbarView()
        createStatusBarView()
        pluginManager = PluginManager(fileSystem!, context: gameContext, host: LocalHost(context: gameContext, files: fileSystem!))
        pluginManager?.add(ExpPlugin())
        pluginManager?.add(AutoMapperPlugin(context: gameContext))
        pluginManager?.loadPlugins()

//        print("Appearance Dark Mode: \(view.isDarkMode), \(view.effectiveAppearance.name)")

//        apperanceObserver = view.observe(\.effectiveAppearance) { [weak self] _, change in
//            print("Appearance changed \(change.oldValue?.name) \(change.newValue?.name)")
//            print("Main app: \(self?.view.isDarkMode), \(self?.view.effectiveAppearance.name)")
//        }

//        gameWindowContainer.backgroundColor = NSColor.blue
//        statusBar.backgroundColor = NSColor.red
//        commandInput.progress = 0.5
//        statusBarController?.roundtime = 25

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

        windowLayoutLoader = WindowLayoutLoader(fileSystem!)
        commandProcessor = CommandProcesssor(fileSystem!, pluginManager: pluginManager!)
        scriptRunner = ScriptRunner(gameContext, loader: ScriptLoader(fileSystem!, context: gameContext))

        authServer = AuthenticationServer()

        gameServer = GameServer { [weak self] state in
            switch state {
            case .connected:
                self?.log.info("connected to game server")
                self?.updateWindowTitle()
                self?.vitalsBar.enabled = true
            case let .data(_, str):
                self?.handleRawStream(data: str, streamData: true)
            case .closed:
                self?.gameStream?.reset()
                self?.logText("\n\(self?.timestamp() ?? "")disconnected from game server\n", mono: true)
                self?.updateWindowTitle()
                self?.vitalsBar.enabled = false
                self?.pauseAllScripts()
                self?.saveSettings()
            }
        }

        gameStream = GameStream(context: gameContext, pluginManager: pluginManager!, streamCommands: { [weak self] command in
            switch command {
            case .text:
                break
            default:
                self?.scriptRunner?.stream("", [command])
            }

            switch command {
            case let .text(tags):
                self?.logTag(tags)

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
                let rounded = Int(ceil(diff))

                self?.gameContext.globalVars["roundtime"] = "\(rounded)"

                DispatchQueue.main.async {
                    self?.roundtime?.set(rounded)
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
                self?.shouldUpdateRoom = true

            case .character:
                self?.updateWindowTitle()
                self?.setGameLogger()

            case let .spell(spell):
                DispatchQueue.main.async {
                    self?.spelltime?.set(spell)
                }

            case .compass:
                DispatchQueue.main.async {
                    self?.statusBarController?.avaialbleDirections = self?.gameContext.availableExits() ?? []
                }

            case .prompt:
                DispatchQueue.main.async {
                    if self?.shouldUpdateRoom == true {
                        self?.shouldUpdateRoom = false
                        self?.updateRoom()
                    }
                }
            case let .launchUrl(maybeurl):
                let url = maybeurl.lowercased().hasPrefix("/forums") ? "http://play.net" + maybeurl : maybeurl
                guard let url = URL(string: url) else {
                    return
                }

                if url.scheme?.hasPrefix("http") == true {
                    NSWorkspace.shared.open(url)
                }

//            default:
//                self?.log.warn("Unhandled command \(command)")
            }
        })

        gameStream?.addHandler(scriptRunner!)

        commandInput.executeCommand = { command in
            self.commandProcessor!.process(command, with: self.gameContext)
        }

//        addWindow(WindowSettings(name: "room", visible: true, closedTarget: nil, x: 0, y: 0, height: 200, width: 800))
//        addWindow(WindowSettings(name: "main", visible: true, closedTarget: nil, x: 0, y: 200, height: 600, width: 800))
//        addWindow(WindowSettings(name: "logons", visible: true, closedTarget: nil, x: 800, y: 0, height: 200, width: 350))
//        addWindow(WindowSettings(name: "thoughts", visible: true, closedTarget: nil, x: 800, y: 200, height: 200, width: 350))
//        addWindow(WindowSettings(name: "percwindow", visible: true, closedTarget: nil, x: 800, y: 400, height: 200, width: 350))
//        addWindow(WindowSettings(name: "inv", visible: false, closedTarget: nil, x: 800, y: 600, height: 200, width: 350))

        gameContext.events2.register(self) { (evt: GameCommandEvent) in
            let command = evt.command
            let text = command.fileName.count > 0 ? "[\(command.fileName)]: \(command.command)\n" : "\(command.command)\n"
            let mono = command.fileName.count > 0 ? true : false

            var preset = command.fileName.count > 0 ? "scriptinput" : nil

            if command.preset.count > 0 {
                preset = command.preset
            }

            self.logText(text, preset: preset, mono: mono, playerCommand: !command.isSystemCommand)
            self.gameServer?.sendCommand(command.command)
        }

        gameContext.events2.register(self) { (evt: CommandEvent) in
            self.commandProcessor?.process(evt.command, with: self.gameContext)
        }

        gameContext.events2.register(self) { (evt: WindowCommandEvent) in
            self.processWindowCommand(evt.action, window: evt.window)
        }

        gameContext.events2.register(self) { (evt: EchoTextEvent) in
            self.logText(evt.text, preset: evt.preset, color: evt.color, mono: evt.mono)
        }

        gameContext.events2.register(self) { (evt: EchoTagEvent) in
            self.logTag([evt.tag])
        }

        gameContext.events2.register(self) { (evt: ErrorEvent) in
            self.logError(evt.error)
        }

        let indicators = ["bleeding", "stunned", "poisoned", "webbed", "burning", "standing", "sitting", "kneeling", "prone", "dead", "hidden", "invisible", "joined"]

        gameContext.events2.register(self) { (evt: VariableChangedEvent) in
            let key = evt.key
            let value = evt.value

            self.pluginManager?.variableChanged(variable: key, value: value)

            if key == "zoneid" || key == "roomid" {
                print("GameViewController - \(key) changed to \(value)")
                self.shouldUpdateRoom = true
            }

            if indicators.contains(key) {
                self.statusBarController?.setIndicator(name: key, enabled: value == "1")
            }
        }

        gameContext.events2.register(self) { (evt: GameParseEvent) in
            self.handleRawStream(data: evt.text, streamData: false)
        }

        vitalsBar.presetFor = { name in
            guard self.vitalsBar.enabled == true else {
                return (self.vitalsBar.disabledForegroundColor, self.vitalsBar.disabledBackgroundColor)
            }

            let preset = self.gameContext.presets[name]
            let fore = preset?.color.asColor() ?? NSColor.white
            let back = preset?.backgroundColor?.asColor() ?? NSColor.blue
            return (fore, back)
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
    }

    func windowShouldClose(_: NSWindow) -> Bool {
        guard gameServer?.isConnected == true else {
            return true
        }

        let alert = NSAlert()
        alert.messageText = "Are you sure you want to close the window? You are currently connected to the game."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.alertStyle = .warning
        let response = alert.runModal()
        return response == .alertFirstButtonReturn
    }

    func windowWillClose(_: Notification) {
        gameContext.events2.unregister(self, DummyEvent<CommandEvent>())
        gameContext.events2.unregister(self, DummyEvent<GameCommandEvent>())
        gameContext.events2.unregister(self, DummyEvent<GameParseEvent>())
        gameContext.events2.unregister(self, DummyEvent<ErrorEvent>())
        gameContext.events2.unregister(self, DummyEvent<EchoTagEvent>())
        gameContext.events2.unregister(self, DummyEvent<EchoTextEvent>())
        gameContext.events2.unregister(self, DummyEvent<VariableChangedEvent>())
        gameContext.events2.unregister(self, DummyEvent<WindowCommandEvent>())
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

    func pauseAllScripts() {
        commandProcessor?.process("#script pause all", with: gameContext)
    }

    func updateWindowTitle() {
        DispatchQueue.main.async {
            if let win = self.view.window {
                let character = self.gameContext.globalVars["charactername"] ?? ""
                let game = self.gameContext.globalVars["game"] ?? ""

                let version = self.appVersion()
                let gameInfo = game.count > 0 ? "\(game)" : ""
                let charInfo = character.count > 0 ? "\(character) - " : ""
                let connection = self.gameServer?.isConnected == true ? "" : " [disconnected]"

                win.title = "\(gameInfo): \(charInfo)Outlander \(version) Beta\(connection)"
                if let m = win as? OWindow {
                    let font = NSFont(name: self.gameContext.layout?.primary.fontName ?? "Helvetica", size: CGFloat(Double(self.gameContext.layout?.primary.fontSize ?? 14)))!
                    m.titleFont = font
                    m.titleColor = self.gameContext.layout?.primary.fontColor.asColor() ?? NSColor(hex: "#d4d4d4")!
                    m.titleBackgroundColor = self.gameContext.layout?.primary.backgroundColor.asColor()
                }
            }
        }
    }

    func appVersion() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let buildStr = dictionary["CFBundleVersion"] as! String
        var build = ""
        if !buildStr.isEmpty, buildStr != "0" {
            build = ".\(buildStr)"
        }
        return "\(version)\(build)"
    }

    func handleRawStream(data: String, streamData: Bool = false) {
        var result = data

        if result.hasPrefix("<") {
            result = pluginManager?.parse(xml: result) ?? result
        }

        if gameContext.applicationSettings.profile.rawLogging {
            gameLog?.rawStream(result)
        }

        if streamData {
            gameStream?.stream(result)
        } else {
            gameStream?.sendToHandlers(text: result)
        }
    }

    func showLogin() {
        loginWindow?.account = gameContext.applicationSettings.profile.account
        loginWindow?.character = gameContext.applicationSettings.profile.character
        loginWindow?.game = gameContext.applicationSettings.profile.game
        loginWindow?.setControlValues()
        view.window?.beginSheet(loginWindow!.window!, completionHandler: { result in
            guard result == .OK else {
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
        profileWindow!.loadProfiles()
        view.window?.beginSheet(profileWindow!.window!, completionHandler: { result in
            guard result == .OK else {
                return
            }

            guard let profile = self.profileWindow!.selected else {
                return
            }

            guard self.gameContext.applicationSettings.profile.name != profile else {
                return
            }

            self.gameContext.applicationSettings.profile.name = profile
            self.loadSettings()
        })
    }

    func showMapWindow() {
        let character = gameContext.globalVars["charactername"] ?? ""
        let game = gameContext.globalVars["game"] ?? ""

        var title = "AutoMapper"

        if !game.isEmpty, !character.isEmpty {
            title = "AutoMapper - \(game): \(character)"
        }

        mapWindow?.window?.title = title
        mapWindow?.showWindow(self)
        mapWindow?.setSelectedZone()
    }

    func loadSettings() {
        ProfileLoader(fileSystem!).load(gameContext)
        gameStream?.monsterCountIgnoreList = gameContext.applicationSettings.profile.monsterIgnore
        setGameLogger()
        reloadWindows(gameContext.applicationSettings.profile.layout) {
            self.reloadTheme()
            self.printSettingsLocations()
            self.logText("Loaded profile \(self.gameContext.applicationSettings.profile.name)\n", mono: false, playerCommand: false)

            self.loginWindow?.account = self.gameContext.applicationSettings.profile.account
            self.loginWindow?.character = self.gameContext.applicationSettings.profile.character
            self.loginWindow?.game = self.gameContext.applicationSettings.profile.game

            self.pluginManager?.initialize(host: LocalHost(context: self.gameContext, files: self.fileSystem!))
            self.updateWindowTitle()
        }
    }

    func printSettingsLocations() {
        logText("Config: \(gameContext.applicationSettings.paths.config.path)\n", mono: false, playerCommand: false)
        logText("Profile: \(gameContext.applicationSettings.currentProfilePath.path)\n", mono: false, playerCommand: false)
        logText("Maps: \(gameContext.applicationSettings.paths.maps.path)\n", mono: false, playerCommand: false)
        logText("Scripts: \(gameContext.applicationSettings.paths.scripts.path)\n", mono: false, playerCommand: false)
        logText("Logs: \(gameContext.applicationSettings.paths.logs.path)\n", mono: false, playerCommand: false)
    }

    func reloadTheme() {
//        commandInput.progress = 0.25
//        statusBarController?.roundtime = 5
        commandInput.textColor = gameContext.presetFor("commandinput")?.color.asColor() ?? NSColor(hex: "#f5f5f5")!
        commandInput.promptBackgroundColor = gameContext.presetFor("commandinput")?.backgroundColor?.asColor() ?? NSColor(hex: "#1e1e1e")!
        statusBarController?.rtTextColor = gameContext.presetFor("roundtime")?.color.asColor() ?? NSColor(hex: "#f5f5f5")!
        statusBarController?.textColor = gameContext.presetFor("statusbartext")?.color.asColor() ?? NSColor(hex: "#f5f5f5")!
        vitalsBar.updateColors()
        commandInput.progressColor = gameContext.presetFor("roundtime")?.backgroundColor?.asColor() ?? NSColor(hex: "#003366")!
        updateWindowTitle()
    }

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
            let layout = buildWindowsLayout()
            windowLayoutLoader?.save(
                applicationSettings!,
                file: "default.cfg",
                windows: layout
            )

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
            openPanel.directoryURL = gameContext.applicationSettings.paths.layout
            openPanel.nameFieldStringValue = gameContext.applicationSettings.profile.layout

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

        if command == "layout:Settings" {
            for (_, win) in gameWindows {
                if win.visible {
                    win.toggleSettings()
                }
            }
            return
        }

        if command == "show:mapwindow" {
            showMapWindow()

            return
        }

        if command == "profile:save" {
            saveSettings()
            return
        }

        log.warn("Unhandled event command \(command)")
    }

    func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        return "[\(formatter.string(from: Date()))]: "
    }

    func saveSettings() {
        ApplicationLoader(fileSystem!).save(gameContext.applicationSettings.paths, context: gameContext)
        ProfileLoader(fileSystem!).save(gameContext)
        logText("\(timestamp())settings saved\n", mono: true, playerCommand: false)
    }

    func buildWindowsLayout() -> WindowLayout {
        let mainWindow = view.window!

        let primary = WindowData()
        primary.name = "primary"
        primary.x = Double(mainWindow.frame.origin.x)
        primary.y = Double(mainWindow.frame.origin.y)
        primary.height = Double(mainWindow.frame.size.height)
        primary.width = Double(mainWindow.frame.size.width)

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

        if action == "hide" || action == "remove" {
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

        logText("Connecting to authentication server at \(host):\(port)\n", mono: true)

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
                    self?.logText("Connecting to game server at \(connection.host):\(connection.port)\n", mono: true)
                    self?.gameServer?.connect(host: connection.host, port: connection.port, key: connection.key)

                case .closed:
                    self?.logText("Disconnected from authentication server\n", mono: true)

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

    func createScriptToolbarView() {
        let storyboard = NSStoryboard(name: "ScriptToolbar", bundle: Bundle.main)
        scriptToolbarController = storyboard.instantiateInitialController() as? ScriptToolbarViewController
        scriptBar.subviews.append(scriptToolbarController!.view)

        scriptToolbarController?.setContext(gameContext)
    }

    func createStatusBarView() {
        let storyboard = NSStoryboard(name: "StatusBar", bundle: Bundle.main)
        statusBarController = storyboard.instantiateInitialController() as? StatusBarViewController
        statusBar.subviews.append(statusBarController!.view)
        statusBarController?.loadImages(context: gameContext)
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
        if let window = gameWindows[name.lowercased()] {
            if window.visible { return name.lowercased() }

            if let closedTarget = window.closedTarget, closedTarget.count > 0 {
                return windowFor(name: closedTarget.lowercased())
            }

            return nil
        }

        if name.lowercased() == "raw" {
            return nil
        }

        return "main"
    }

    func maybeCreateWindow(_ name: String, title: String?, closedTarget: String? = nil) {
        let lower = name.lowercased()
        guard gameWindows[lower] == nil else {
            gameWindows[lower]?.windowTitle = title
            return
        }

        let settings = WindowData()
        settings.name = lower
        settings.title = title
        settings.closedTarget = closedTarget
        settings.visible = false
        settings.x = 0
        settings.y = 0
        settings.height = 200
        settings.width = 300
        settings.autoScroll = true

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

    enum KeyCodes: UInt16 {
        case delete = 51
        case home = 115
        case end = 119
        case leftArrow = 123
        case rightArrow = 134
        case enter = 36
    }

    func createWindow(_ settings: WindowData) -> WindowViewController? {
        let storyboard = NSStoryboard(name: "Window", bundle: Bundle.main)
        let controller = storyboard.instantiateInitialController() as? WindowViewController

        controller?.onKeyUp = { event in
            guard let val = event.charactersIgnoringModifiers, let regex = RegexFactory.get("[a-zA-Z0-9\\!\\\\\"\\#\\$\\%\\&\\'\\(\\)\\*\\+\\,\\\\\\-\\./:;<=>\\?@\\[\\]\\^_`{|}~]") else {
                return
            }

            let key = KeyCodes(rawValue: event.keyCode)

            let matches = regex.allMatches(val)

            guard !self.commandInput.hasFocus(), matches.count > 0 || key != nil else {
                return
            }

            var sendInput = false

            var newVal = self.commandInput.stringValue
            var targetIndex = newVal.count

            switch key {
            case .delete:
                newVal = String(newVal.dropLast(1))
                targetIndex = newVal.count
            case .leftArrow:
                targetIndex -= 1
            case .rightArrow:
                break
            case .home:
                targetIndex = 0
            case .end:
                break
            case .enter:
                sendInput = true
            default:
                newVal = newVal + val
                targetIndex = newVal.count
            }

            self.commandInput.stringValue = newVal
            self.commandInput.selectText(self)
            self.commandInput.currentEditor()?.selectedRange = NSMakeRange(targetIndex, 0)

            if sendInput {
                self.commandInput.commitHistory()
            }
        }

        controller?.gameContext = gameContext

        controller?.name = settings.name
        controller?.visible = settings.visible ?? true
        controller?.closedTarget = settings.closedTarget
        controller?.fontName = settings.fontName
        controller?.fontSize = settings.fontSize
        controller?.monoFontName = settings.monoFontName
        controller?.monoFontSize = settings.monoFontSize
        controller?.foregroundColor = settings.fontColor
        controller?.backgroundColor = settings.backgroundColor
        controller?.borderColor = settings.borderColor
        controller?.displayBorder = settings.showBorder ?? true
        controller?.displayTimestamp = settings.timestamp ?? false
        controller?.bufferSize = settings.bufferSize
        controller?.bufferClearSize = settings.bufferClearSize
        controller?.location = NSRect(x: settings.x, y: settings.y, width: settings.width, height: settings.height)
        controller?.padding = settings.padding
        controller?.autoScroll = settings.autoScroll ?? true

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
        logTag([TextTag.tagFor(text, window: "main", mono: mono, color: color, preset: preset, playerCommand: playerCommand)])
    }

    func logError(_ text: String) {
        logTag([TextTag(text: text, window: "main", mono: true, preset: "scripterror")])
    }

    private var logBuilder = LogBuilder()
    func logTag(_ tags: [TextTag]) {
        for tag in tags {
            guard let windowName = windowFor(name: tag.window), let window = gameWindows[windowName] else {
                continue
            }

            logBuilder.append(tag, windowName: windowName, context: gameContext)

            window.append(tag)
        }

        logBuilder.flush(gameLog)
    }
}
