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
    var windows: [NSWindow] = []
    var rootUrl: URL?

    var activeWindow: NSWindow? {
        var win = NSApplication.shared.keyWindow

        if win == nil, windows.count > 0 {
            win = windows[0]
        }

        return win
    }

    var activeController: GameViewController? {
        activeWindow?.contentViewController as? GameViewController
    }

    func applicationDidFinishLaunching(_: Notification) {
        LogManager.getLog = { name in
            PrintLogger(name)
        }

        AppDelegate.mainMenu.instantiate(withOwner: NSApplication.shared, topLevelObjects: nil)

        Preferences.workingDirectoryBookmark = nil

        if let rootUrl = BookmarkHelper().promptOrRestore() {
            self.rootUrl = rootUrl
        }

        makeWindow(rootUrl)
    }

    func makeWindow(_ rootUrl: URL?) {
        let bundle = Bundle(for: GameViewController.self)
        let storyboard = NSStoryboard(name: "Game", bundle: bundle)

        let window = MyWindow(
            contentRect: NSMakeRect(0, 0, NSScreen.main!.frame.midX, NSScreen.main!.frame.midY),
            styleMask: [.titled, .resizable, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.setFrameAutosaveName("")

        window.title = "Outlander 2"
        window.center()
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true

        let controller = storyboard.instantiateInitialController() as! GameViewController
        window.registerKeyHandlers(controller.gameContext)

        let settings = ApplicationSettings()
        if let root = rootUrl {
            settings.paths.rootUrl = root
        }
        controller.applicationSettings = settings

        ApplicationLoader(LocalFileSystem(settings)).load(settings.paths, context: controller.gameContext)

        window.contentViewController = controller
        window.delegate = controller

        window.makeKeyAndOrderFront(nil)

        windows.append(window)
    }

    func applicationWillTerminate(_: Notification) {
        windows.removeAll()
    }

    @IBAction func preferences(_: Any) {
        print("Preferences")
    }

    @IBAction func connect(_: Any) {
        activeController?.showLogin()
    }

    @IBAction func connectProfile(_: Any) {
        activeController?.showProfileSelection()
    }

    @IBAction func saveProfile(_: Any) {
        sendCommand("profile:save")
    }

    @IBAction func newGame(_: Any) {
        makeWindow(rootUrl)
    }

    @IBAction func showMapWindow(_: Any) {
        sendCommand("show:mapwindow")
    }

    @IBAction func loadDefaultLayoutAction(_: Any) {
        sendCommand("layout:LoadDefault")
    }

    @IBAction func saveDefaultLayoutAction(_: Any) {
        sendCommand("layout:SaveDefault")
    }

    @IBAction func loadLayoutAction(_: Any) {
        sendCommand("layout:Load")
    }

    @IBAction func saveLayoutAsAction(_: Any) {
        sendCommand("layout:SaveAs")
    }

    func sendCommand(_ command: String) {
        activeController?.command(command)
    }

    static var mainMenu: NSNib {
        guard let nib = NSNib(nibNamed: NSNib.Name("MainMenu"), bundle: Bundle.main) else {
            fatalError("Resource `MainMenu.xib` is not found in the bundle `\(Bundle.main.bundlePath)`")
        }
        return nib
    }
}

class MyWindow: NSWindow {
    @IBInspectable
    public var titleColor = NSColor(hex: "#f5f5f5")! {
        didSet {
            updateTitle()
        }
    }

    @IBInspectable
    public var titleBackgroundColor: NSColor? {
        didSet {
            updateTitle()
        }
    }

    @IBInspectable
    public var titleFont = NSFont(name: "Helvetica", size: 14)! {
        didSet {
            updateTitle()
        }
    }

    var gameContext: GameContext?

    func registerKeyHandlers(_ gameContext: GameContext) {
        self.gameContext = gameContext

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.macroKeyDown(with: $0) { return nil }
            return $0
        }
    }

    func macroKeyDown(with event: NSEvent) -> Bool {
        // handle keyDown only if current window has focus, i.e. is keyWindow
        guard NSApplication.shared.keyWindow === self else { return false }

        guard let found = gameContext?.findMacro(description: event.macro) else {
            return false
        }

        gameContext?.events.sendCommand(Command2(command: found.action))
        return true
    }

    func updateTitle() {
        guard let windowContentView = contentView else {
            return
        }
        guard let contentSuperView = windowContentView.superview else {
            return
        }

        let titleView = findViewInSubview(contentSuperView.subviews, ignoreView: windowContentView, test: { view in
            view is NSTextField
        })

        guard let titleText = titleView as? NSTextField else {
            return
        }

        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: titleColor,
        ]

        if let bg = titleBackgroundColor {
            attributes[.backgroundColor] = bg
        }

        titleText.attributedStringValue = NSAttributedString(string: title, attributes: attributes)
    }

    func findViewInSubview(_ subviews: [NSView], ignoreView: NSView, test: (NSView) -> Bool) -> NSView? {
        for v in subviews {
            if test(v) {
                return v
            } else if v != ignoreView {
                if let found = findViewInSubview(v.subviews as [NSView], ignoreView: ignoreView, test: test) {
                    return found
                }
            }
        }
        return nil
    }
}

struct AppState {
    var fieldText = ""
    var gameText = "this is some text"
    var showHealthBars = false
    var sendCommand: (String) -> Void = { _ in }
    var login: () -> Void = {}

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

        case let .text(value):
//            print("field: \(value)")
            fieldText = value
            return []

        case .toggleHealthBars:
            print("Toggling")
            showHealthBars = !showHealthBars
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
            .vitalBarItem("spirit", value: 1, backgroundColor: NSColor(hex: "#400040")),
        ], axis: .horizontal, distribution: .fillEqually, alignment: .top, spacing: 0)

        var views: [View<AppState.Message>] = [
            .textView(text: gameText),
            .textField(text: fieldText, onChange: { value in .text(value) }),
            .stackView([
                .button(text: "Command", onClick: .command),
                .button(text: "Login", onClick: .login),
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
