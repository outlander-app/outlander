//
//  ScriptToolbarViewController.swift
//  Outlander
//
//  Created by Joe McBride on 11/28/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

class ScriptToolbarViewController: NSViewController {
    private var context: GameContext?

    private var font: String = "Menlo"
    private var fontSize: CGFloat = 12

    override func viewDidLoad() {
        super.viewDidLoad()

//        addScript("idle")
//        addScript("hunt")
//        addScript("longer/one")
//        addScript("a long script name")
//        addScript("hunt 2")
//        addScript("hunt 3")
//        addScript("hunt 4")
    }

    func setContext(_ context: GameContext) {
        self.context = context

        context.events.handle(self, channel: "ol:script:add") { result in
            guard let name = result as? String else {
                return
            }
            
            DispatchQueue.main.async {
                self.addScript(name)
            }
        }

        context.events.handle(self, channel: "ol:script:pause") { result in
            guard let name = result as? String else {
                return
            }
            
            DispatchQueue.main.async {
                self.pauseScript(name)
            }
        }

        context.events.handle(self, channel: "ol:script:resume") { result in
            guard let name = result as? String else {
                return
            }
            
            DispatchQueue.main.async {
                self.resumeScript(name)
            }
        }

        context.events.handle(self, channel: "ol:script:remove") { result in
            guard let name = result as? String else {
                return
            }
            
            DispatchQueue.main.async {
                self.removeScript(name)
            }
        }

        context.events.handle(self, channel: "ol:script:removeall") { _ in
            DispatchQueue.main.async {
                self.removeAll()
            }
        }
    }

    func resumeScript(_ scriptName:String) {
        for view in self.view.subviews {
            if let button = view as? NSPopUpButton {
                if button.menu?.title == scriptName || scriptName == "all" {
                    button.menu?.item(at: 0)?.image = NSImage(named: "NSStatusAvailable")
                }
            }
        }
    }
    
    func pauseScript(_ scriptName:String) {
        for view in self.view.subviews {
            if let button = view as? NSPopUpButton {
                if button.menu?.title == scriptName || scriptName == "all" {
                    button.menu?.item(at: 0)?.image = NSImage(named: "NSStatusPartiallyAvailable")
                }
            }
        }
    }

    func removeAll() {
        for view in self.view.subviews {
            if let button = view as? NSPopUpButton {
                button.removeFromSuperview()
            }
        }
    }

    func removeScript(_ scriptName:String) {
        let startCount = self.view.subviews.count
        
        for view in self.view.subviews {
            if let button = view as? NSPopUpButton {
                if button.menu?.title == scriptName {
                    button.removeFromSuperview()
                }
            }
        }
        
        if self.view.subviews.count != startCount {
            updateButtonFrames()
        }
    }

    @objc func popUpSelectionChanged(_ notification:Notification) {
        if let menuItem = notification.userInfo?["MenuItem"] as? NSMenuItem {
            if menuItem.tag == -1 {
                return
            }

            let action = menuItem.attributedTitle?.string.lowercased() ?? ""
            if action == "" {
                return
            }
            let scriptName = menuItem.menu!.title
            self.context?.events.sendCommand(Command2(command: "#script \(action) \(scriptName)", isSystemCommand: true))
        }
    }

    @objc func debugMenuItemSelection(_ target:NSMenuItem) {
        let level = ScriptLogLevel(rawValue: target.tag) ?? ScriptLogLevel.none
        let scriptName = target.menu!.title
        self.context?.events.sendCommand(Command2(command: "#script debug \(scriptName) \(level.rawValue)", isSystemCommand: true))
    }

    func updateButtonFrames() {
        var width: CGFloat = 125
        var offset: CGFloat = 0
        let count = self.view.subviews.count
        let max = 5
        for view in self.view.subviews {
            if let button = view as? NSPopUpButton {
                if let title = button.menu?.title {
                    if count <= max {
                        width = NSString(string: title).size(withAttributes: [.font: NSFont(name: self.font, size: self.fontSize)!]).width
                        width += 40
                    } else {
                        width = 75
                    }
                }
                button.frame = NSRect(x: offset, y: 0, width: width, height: 25)
                offset += button.frame.width
            }
        }
    }

    func addScript(_ scriptName: String) {
        let buttonFont = NSFont(name: self.font, size: self.fontSize)!

        let frame = NSRect(x: 0, y: 0, width: 75, height: 25)

        let btn = NSPopUpButton(frame: frame, pullsDown: true)
        btn.setButtonType(.switch)
        btn.font = buttonFont
        btn.menu = NSMenu(title: scriptName)
        btn.menu?.addItem(createMenuItem(scriptName, textColor: NSColor.white))
        btn.menu?.item(at: 0)?.image = NSImage(named: "NSStatusAvailable")
        let namedItem = createMenuItem(scriptName, textColor: NSColor.black)
        namedItem.isEnabled = false
        namedItem.tag = -1
        btn.menu?.addItem(namedItem)
        btn.menu?.addItem(createMenuItem("Resume", textColor: NSColor.black))
        btn.menu?.item(at: 2)?.image = NSImage(named: "NSStatusAvailable")
        btn.menu?.addItem(createMenuItem("Pause", textColor: NSColor.black))
        btn.menu?.item(at: 3)?.image = NSImage(named: "NSStatusPartiallyAvailable")
        btn.menu?.addItem(createMenuItem("Abort", textColor: NSColor.black))
        btn.menu?.item(at: 4)?.image = NSImage(named: "NSStatusUnavailable")
        
        btn.menu?.insertItem(NSMenuItem.separator(), at: 5)

        let debugMenu = createMenuItem("Debug", textColor: NSColor.black)
        debugMenu.submenu = NSMenu(title: scriptName)
        debugMenu.submenu?.addItem(createSubMenuItem("0. Debug off", textColor: NSColor.black, tag: ScriptLogLevel.none))
        debugMenu.submenu?.addItem(createSubMenuItem("1. Goto, gosub, return, labels", textColor: NSColor.black, tag: ScriptLogLevel.gosubs))
        debugMenu.submenu?.addItem(createSubMenuItem("2. Pause, wait, waitfor, move", textColor: NSColor.black, tag: ScriptLogLevel.wait))
        debugMenu.submenu?.addItem(createSubMenuItem("3. If evaluations", textColor: NSColor.black, tag: ScriptLogLevel.if))
        debugMenu.submenu?.addItem(createSubMenuItem("4. Math, variables", textColor: NSColor.black, tag: ScriptLogLevel.vars))
        debugMenu.submenu?.addItem(createSubMenuItem("5. Actions", textColor: NSColor.black, tag: ScriptLogLevel.actions))
        btn.menu?.addItem(debugMenu)
        btn.menu?.item(at: 6)?.image = NSImage(named: "NSStatusNone")
        
        btn.menu?.addItem(createMenuItem("Trace", textColor: NSColor.black))
        btn.menu?.item(at: 7)?.image = NSImage(named: "NSStatusNone")

        btn.menu?.addItem(createMenuItem("Vars", textColor: NSColor.black))
        btn.menu?.item(at: 8)?.image = NSImage(named: "NSStatusNone")

        view.subviews.append(btn)

        NotificationCenter.default.addObserver(self, selector: #selector(ScriptToolbarViewController.popUpSelectionChanged(_:)), name: NSMenu.didSendActionNotification, object: btn.menu)

        updateButtonFrames()
    }

    func createMenuItem(_ title:String, textColor:NSColor) -> NSMenuItem {
        let item = NSMenuItem()
        let titleString = createTitleString(title, textColor: textColor)
        item.attributedTitle = titleString
        return item
    }

    func createSubMenuItem(_ title:String, textColor:NSColor, tag: ScriptLogLevel) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: #selector(ScriptToolbarViewController.debugMenuItemSelection(_:)), keyEquivalent: "")
        item.target = self
        let titleString = createTitleString(title, textColor: textColor)
        item.attributedTitle = titleString
        item.tag = tag.rawValue
        return item
    }

    func createTitleString(_ title:String, textColor:NSColor) -> NSAttributedString {
        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: NSFont(name: self.font, size: self.fontSize)!,
        ]

        let style = NSMutableParagraphStyle()
        style.lineBreakMode = NSLineBreakMode.byTruncatingTail
        attributes[.paragraphStyle] = style
        
        return NSAttributedString(string: title, attributes: attributes)
    }
}
