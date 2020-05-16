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

    var activeController: GameViewController? {
        get {
            var win = NSApplication.shared.keyWindow

            if win == nil && windows.count > 0 {
                win = windows[0]
            }

            return win?.contentViewController as? GameViewController
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.mainMenu.instantiate(withOwner: NSApplication.shared, topLevelObjects: nil)

//        Preferences.workingDirectoryBookmark = nil

        if let rootUrl = BookmarkHelper().promptOrRestore() {
            self.rootUrl = rootUrl
        }

        makeWindow(self.rootUrl)
    }

    func makeWindow(_ rootUrl: URL?) {
        let bundle = Bundle(for: GameViewController.self)
        let storyboard = NSStoryboard(name: "Game", bundle: bundle)
        let controller = storyboard.instantiateInitialController() as? GameViewController

        let settings = ApplicationSettings()
        if let root = rootUrl {
            settings.paths.rootUrl = root
        }
        controller?.applicationSettings = settings

        let window = NSWindow(
            contentRect: NSMakeRect(0, 0, NSScreen.main!.frame.midX, NSScreen.main!.frame.midY),
            styleMask: [.titled, .resizable, .closable, .miniaturizable],
            backing: .buffered,
            defer: false)

        window.title = "Outlander 2"
        window.center()
        window.isMovableByWindowBackground = true
        
        window.contentViewController = controller
        
        window.makeKeyAndOrderFront(nil)
        
        self.windows.append(window)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.windows.removeAll()
    }

    @IBAction func preferences(_ sender: Any) {
        print("Preferences")
    }

    @IBAction func newGame(_ sender: Any) {
        self.makeWindow(self.rootUrl)
    }

    @IBAction func loadDefaultLayoutAction(_ sender: Any) {
        sendCommand("layout:LoadDefault")
    }
    
    @IBAction func saveDefaultLayoutAction(_ sender: Any) {
        sendCommand("layout:SaveDefault")
    }
    
    @IBAction func loadLayoutAction(_ sender: Any) {
        sendCommand("layout:Load")
    }
    
    @IBAction func saveLayoutAsAction(_ sender: Any) {
        sendCommand("layout:SaveAs")
    }
    
    func sendCommand(_ command: String) {
        self.activeController?.command(command)
    }
    
    static var mainMenu: NSNib {
       guard let nib = NSNib(nibNamed: NSNib.Name("MainMenu"), bundle: Bundle.main) else {
          fatalError("Resource `MainMenu.xib` is not found in the bundle `\(Bundle.main.bundlePath)`")
       }
       return nib
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
