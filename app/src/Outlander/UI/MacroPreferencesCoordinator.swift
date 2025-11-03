//
//  MacroPreferencesCoordinator.swift
//  Outlander
//
//  Created by Codex on 5/18/25.
//

import Cocoa

enum MacroPreferencesCategory: String, CaseIterable {
    case letters = "A–Z Macros"
    case keypad = "Keypad Macros"
    case function = "Function Macros"

    var title: String { rawValue }
}

final class MacroPreferencesCoordinator {
    private let contextProvider: () -> GameContext?
    private var controllers: [MacroPreferencesCategory: MacroPreferencesWindowController] = [:]

    init(contextProvider: @escaping () -> GameContext?) {
        self.contextProvider = contextProvider
    }

    func showWindow(for category: MacroPreferencesCategory) {
        guard let context = contextProvider() else {
            presentNoContextAlert()
            return
        }

        let controller = controller(for: category)
        controller.updateContext(context)
        controller.showWindow(self)
        controller.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func controller(for category: MacroPreferencesCategory) -> MacroPreferencesWindowController {
        if let existing = controllers[category] {
            return existing
        }

        let controller = MacroPreferencesWindowController(category: category)
        controllers[category] = controller
        return controller
    }

    private func presentNoContextAlert() {
        let alert = NSAlert()
        alert.messageText = "No active game window"
        alert.informativeText = "Open or select a game window before editing macros."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

final class MacroPreferencesWindowController: NSWindowController {
    private let category: MacroPreferencesCategory
    private let macroViewController: MacroPreferencesViewController

    init(category: MacroPreferencesCategory) {
        self.category = category
        self.macroViewController = MacroPreferencesViewController(category: category)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = category.title
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 520, height: 360)

        super.init(window: window)

        window.contentViewController = macroViewController
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        guard let window else { return }
        window.center()
    }

    func updateContext(_ context: GameContext) {
        macroViewController.updateContext(context)
    }
}
