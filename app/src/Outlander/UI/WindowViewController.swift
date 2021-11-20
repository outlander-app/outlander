//
//  GameWindowViewController.swift
//  Outlander
//
//  Created by Joseph McBride on 12/7/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

class OLScrollView: NSScrollView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        verticalScroller?.scrollerStyle = .overlay
        horizontalScroller?.scrollerStyle = .overlay
    }

    override open var scrollerStyle: NSScroller.Style {
        get { .overlay }
        set {
            self.verticalScroller?.scrollerStyle = .overlay
            self.horizontalScroller?.scrollerStyle = .overlay
        }
    }

    override var isFlipped: Bool { true }
}

class WindowViewController: NSViewController, NSUserInterfaceValidations, NSTextViewDelegate {
    static var dateFormatter = DateFormatter()

    @IBOutlet var mainView: OView!
    @IBOutlet var textView: NSTextView!

    public var gameContext: GameContext?
    public var name: String = "" {
        didSet {
            mainView?.name = name
        }
    }

    public var windowTitle: String?
    public var visible: Bool = true
    public var closedTarget: String?
    public var bufferSize: Int = 0
    public var bufferClearSize: Int = 0

    private var foregroundNSColor: NSColor = WindowViewController.defaultFontColor
    private var fontNSFont: NSFont = WindowViewController.defaultFont
    private var monoFontNSFont: NSFont = WindowViewController.defaultMonoFont

    public var borderColor: String = "#cccccc" {
        didSet {
            mainView?.borderColor = NSColor(hex: borderColor) ?? WindowViewController.defaultFontColor
        }
    }

    public var borderWidth: CGFloat = 1 {
        didSet {
            mainView?.borderWidth = borderWidth
        }
    }

    public var foregroundColor: String = "#cccccc" {
        didSet {
            foregroundNSColor = NSColor(hex: foregroundColor) ?? WindowViewController.defaultFontColor
        }
    }

    public var backgroundColor: String = "#1e1e1e" {
        didSet {
            textView?.backgroundColor = NSColor(hex: backgroundColor) ?? WindowViewController.defaultBorderColor
        }
    }

    public var displayBorder: Bool = false {
        didSet {
            mainView?.displayBorder = displayBorder
        }
    }

    public var displayTimestamp: Bool = false

    public var fontName: String = "Helvetica" {
        didSet {
            fontNSFont = NSFont(name: fontName, size: CGFloat(fontSize)) ?? WindowViewController.defaultFont
        }
    }

    public var fontSize: Double = 14 {
        didSet {
            fontNSFont = NSFont(name: fontName, size: CGFloat(fontSize)) ?? WindowViewController.defaultFont
        }
    }

    public var monoFontName: String = "Menlo" {
        didSet {
            monoFontNSFont = NSFont(name: fontName, size: CGFloat(monoFontSize)) ?? WindowViewController.defaultFont
        }
    }

    public var monoFontSize: Double = 13 {
        didSet {
            monoFontNSFont = NSFont(name: monoFontName, size: CGFloat(monoFontSize)) ?? WindowViewController.defaultMonoFont
        }
    }

    private var lastLocation = NSRect.zero
    public var location: NSRect {
        get {
            if view.superview != nil {
                return view.frame
            }

            return lastLocation
        }
        set {
            lastLocation = newValue
            view.setFrameSize(NSSize(width: newValue.width, height: newValue.height))
            view.setFrameOrigin(NSPoint(x: newValue.origin.x, y: newValue.origin.y))
        }
    }

    static var defaultFontColor = NSColor(hex: "#cccccc")!
    static var defaultFont = NSFont(name: "Helvetica", size: 14)!
    static var defaultMonoFont = NSFont(name: "Menlo", size: 13)!
    static var defaultCreatureColor = NSColor(hex: "#ffff00")!
    static var defaultBorderColor = NSColor(hex: "#1e1e1e")!

    var lastTag: TextTag?
    var queue: DispatchQueue?

    var suspended: Bool = false
    var suspendedQueue: [TextTag] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        WindowViewController.dateFormatter.dateFormat = "HH:mm"

        updateTheme()

        textView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: foregroundNSColor,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
            NSAttributedString.Key.cursor: NSCursor.pointingHand,
        ]

        queue = DispatchQueue(label: "ol:\(name):window\(UUID().uuidString)", qos: .userInteractive)

        if textView.menu?.item(withTitle: "Clear") == nil {
            textView.menu?.insertItem(NSMenuItem.separator(), at: 0)
        }

        addMenu(title: "Close Window", action: #selector(closeWindow(sender:)))
        addMenu(title: "Show Border", action: #selector(toggleShowBorder(sender:)))
        addMenu(title: "Timestamp", action: #selector(toggleTimestamp(sender:)))
        addMenu(title: "Clear", action: #selector(clear(sender:)))
        addMenu(tag: 42, action: #selector(menuTitle(sender:)))
    }

    func toWindowData(order: Int = 0) -> WindowData {
        let data = WindowData()
        data.name = name
        data.title = title?.count == 0 ? nil : title
        data.visible = visible ? 1 : 0
        data.showBorder = displayBorder ? 1 : 0
        data.borderColor = borderColor
        data.timestamp = displayTimestamp ? 1 : 0
        data.closedTarget = closedTarget?.count == 0 ? nil : closedTarget
        data.fontColor = foregroundColor
        data.backgroundColor = backgroundColor
        data.fontName = fontName
        data.fontSize = fontSize
        data.monoFontName = monoFontName
        data.monoFontSize = monoFontSize

        data.bufferSize = bufferSize
        data.bufferClearSize = bufferClearSize

        data.width = Double(mainView?.frame.width ?? 100)
        data.height = Double(mainView?.frame.height ?? 100)
        data.x = Double(lastLocation.origin.x)
        data.y = Double(lastLocation.origin.y)
        data.order = order

        return data
    }

    func hide() {
        if view.superview != nil {
            lastLocation = view.frame
        }
        view.removeFromSuperview()
        visible = false
    }

    func addMenu(title: String, action: Selector?) {
        if let menu = textView.menu {
            let menuItem = menu.item(withTitle: title)
            if menuItem == nil {
                menu.insertItem(withTitle: title, action: action, keyEquivalent: "", at: 0)
            }
        }
    }

    func addMenu(tag: Int, action: Selector?) {
        if let menu = textView.menu {
            var menuItem = menu.item(withTag: tag)
            if menuItem == nil {
                menuItem = menu.insertItem(withTitle: "", action: action, keyEquivalent: "", at: 0)
                menuItem?.tag = tag
                menu.insertItem(NSMenuItem.separator(), at: 1)
            }
        }
    }

    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(menuTitle(sender:)) {
            let menuItem = item as! NSMenuItem
            menuItem.title = "\"\(self.name)\""
        }
        if item.action == #selector(toggleTimestamp(sender:)) {
            let menuItem = item as! NSMenuItem
            menuItem.state = self.displayTimestamp ? .on : .off
        }
        if item.action == #selector(toggleShowBorder(sender:)) {
            let menuItem = item as! NSMenuItem
            menuItem.state = self.mainView.displayBorder ? .on : .off
        }
        return true
    }

    @objc func closeWindow(sender _: Any?) {
        gameContext?.events.sendCommand(Command2(command: "#window hide \(name)", isSystemCommand: true))
    }

    @objc func toggleShowBorder(sender _: Any?) {
        mainView.displayBorder = !mainView.displayBorder
    }

    @objc func toggleTimestamp(sender _: Any?) {
        print("toggle timestamp")
        displayTimestamp = !displayTimestamp
    }

    @objc func clear(sender _: Any?) {
        clear()
    }

    @objc func menuTitle(sender _: Any?) {}

    func updateTheme() {
        mainView?.name = name
        mainView?.displayBorder = displayBorder
        mainView?.borderWidth = borderWidth
        mainView?.borderColor = NSColor(hex: borderColor) ?? WindowViewController.defaultFontColor
        mainView?.backgroundColor = NSColor(hex: borderColor) ?? WindowViewController.defaultFontColor
        textView?.backgroundColor = NSColor(hex: backgroundColor) ?? WindowViewController.defaultBorderColor
    }

    func clear() {
        guard !Thread.isMainThread else {
            textView.string = ""
            return
        }

        DispatchQueue.main.sync {
            self.textView.string = ""
        }
    }

    func clearAndAppend(_ tags: [TextTag], highlightMonsters: Bool = false) {
        guard let context = gameContext else {
            return
        }
        queue?.async {
            let target = NSMutableAttributedString()

            var first = true

            for tag in tags {
                let text = self.processSubs(tag.text)

                let displayTimestamp = first && self.displayTimestamp

                if let str = self.stringFromTag(tag, text: text) {
                    if displayTimestamp, let stampStr = self.createTimestamp(for: tag) {
                        target.append(stampStr)
                    }
                    
                    target.append(str)
                }
                first = false
            }

            self.processHighlights(target, context: context, highlightMonsters: highlightMonsters)
            self.setWithoutProcessing(target)
        }
    }

    func stringFromTag(_ tag: TextTag, text: String) -> NSMutableAttributedString? {
        guard let context = gameContext else {
            return nil
        }

        var foregroundColorToUse = foregroundNSColor
        var backgroundHex = tag.backgroundColor

        if tag.bold {
            if let value = context.presetFor("creatures") {
                foregroundColorToUse = NSColor(hex: value.color) ?? WindowViewController.defaultCreatureColor
            }
        }

        if let preset = tag.preset, let value = context.presetFor(preset) {
            foregroundColorToUse = NSColor(hex: value.color) ?? foregroundNSColor
            backgroundHex = value.backgroundColor
        }

        if let foreColorHex = tag.color, let foreColor = NSColor(hex: foreColorHex) {
            foregroundColorToUse = foreColor
        }

        var font = fontNSFont
        if tag.mono {
            font = monoFontNSFont
        }

        var attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: foregroundColorToUse,
            NSAttributedString.Key.font: font,
        ]

        if let bgColor = backgroundHex {
            attributes[NSAttributedString.Key.backgroundColor] = NSColor(hex: bgColor) ?? nil
        }

        if let href = tag.href {
            attributes[NSAttributedString.Key.link] = href
        }

        if let command = tag.command {
            attributes[NSAttributedString.Key.link] = "command:\(command)"
        }

//        var stamped = text
//
//        if timestamp {
//            stamped = "[\(WindowViewController.dateFormatter.string(from: Date()))] \(text)"
//        }

        return NSMutableAttributedString(string: text, attributes: attributes)
    }

    func processHighlights(_ text: NSMutableAttributedString, context: GameContext, highlightMonsters: Bool = false) {
        var highlights = context.activeHighlights()

        var str = text.string

        if highlightMonsters {
            if let ignore = context.globalVars["monsterlist"] {
                if let creatures = context.presetFor("creatures") {
                    let hl = Highlight(foreColor: creatures.color, backgroundColor: creatures.backgroundColor ?? "", pattern: ignore, className: "", soundFile: "")
                    highlights.insert(hl, at: 0)
                }
            }
        }

        for h in highlights {
            guard let regex = RegexFactory.get(h.pattern) else {
                continue
            }

            let matches = regex.allMatches(&str)
            for match in matches {
                guard let range = match.rangeOf(index: 0), range.length > 0 else {
                    continue
                }

                text.addAttribute(
                    NSAttributedString.Key.foregroundColor,
                    value: NSColor(hex: h.foreColor) ?? WindowViewController.defaultFontColor,
                    range: range
                )

                if h.backgroundColor.count > 0 {
                    guard let bgColor = NSColor(hex: h.backgroundColor) else {
                        continue
                    }

                    text.addAttribute(
                        NSAttributedString.Key.backgroundColor,
                        value: bgColor,
                        range: range
                    )
                }

                if h.soundFile.count > 0 {
                    context.events.sendCommand(Command2(command: "#play \(h.soundFile)", isSystemCommand: true))
                }
            }
        }
    }

    func processSubs(_ text: String) -> String {
        guard let context = gameContext else {
            return text
        }

        var result = text

        for sub in context.activeSubs() {
            guard let regex = RegexFactory.get(sub.pattern) else {
                continue
            }

            result = regex.replace(result, with: sub.action)
        }

        return result
    }

    func processGags(_ text: String) -> Bool {
        guard let context = gameContext else {
            return false
        }

        for gag in context.gags {
            guard let regex = RegexFactory.get(gag.pattern) else {
                continue
            }

            if regex.hasMatches(text) {
                return true
            }
        }

        return false
    }

    func append(_ tag: TextTag) {
        guard let context = gameContext else {
            return
        }

        if tag.text.hasPrefix("@suspend@") {
            suspended = true
            return
        }

        if tag.text.hasPrefix("@resume@") {
            suspended = false
            clearAndAppend(suspendedQueue)
            suspendedQueue.removeAll()
            return
        }

        if suspended {
            suspendedQueue.append(tag)
            return
        }

        queue?.async {
            if self.lastTag?.isPrompt == true, !tag.playerCommand {
                // skip multiple prompts of the same type
                if tag.isPrompt, self.lastTag?.text == tag.text {
                    return
                }

                self.appendWithoutProcessing(NSAttributedString(string: "\n"))
            }

            self.lastTag = tag

            // Check if the text should be gagged or not
            if self.processGags(tag.text) {
                return
            }

            let displayTimestamp = self.displayTimestamp && !tag.playerCommand

            let text = self.processSubs(tag.text)
            guard let str = self.stringFromTag(tag, text: text) else { return }
            self.processHighlights(str, context: context)

            if displayTimestamp {
                if let stampStr = self.createTimestamp(for: tag) {
                    self.appendWithoutProcessing(stampStr)
                }
            }

            self.appendWithoutProcessing(str)
        }
    }

    func createTimestamp(for tag: TextTag) -> NSAttributedString? {
        let stamp = "[\(WindowViewController.dateFormatter.string(from: Date()))] "
        return self.stringFromTag(TextTag.tagFor(stamp, mono: tag.mono), text: stamp)
    }

    func appendWithoutProcessing(_ text: NSAttributedString) {
        // DO NOT add highlights, etc.
        DispatchQueue.main.async {
            let percentScroll = self.textView.visibleRect.maxY / self.textView.bounds.maxY
            let smartScroll = percentScroll >= CGFloat(0.95)

            if self.name == "main" {
                print("** Window rect: \(percentScroll)% \(self.textView.visibleRect.maxY) / \(self.textView.bounds.maxY)")
            }

            self.textView.textStorage?.append(text)

            if smartScroll {
                self.textView.scrollToEndOfDocument(self)
            }
        }
    }

    func setWithoutProcessing(_ text: NSMutableAttributedString) {
        // DO NOT add highlights, etc.
        DispatchQueue.main.async {
            let percentScroll = self.textView.visibleRect.maxY / self.textView.bounds.maxY
            let smartScroll = percentScroll >= CGFloat(0.95)

            self.textView.textStorage?.setAttributedString(text)

            if smartScroll {
                self.textView.scrollToEndOfDocument(self)
            }
        }
    }

    func textView(_: NSTextView, clickedOnLink link: Any, at _: Int) -> Bool {
        guard let value = link as? String else {
            return false
        }

        if value.hasPrefix("command:") {
            let cmd = value[8...]
            if cmd.count > 0 {
                gameContext?.events.sendCommand(Command2(command: cmd, isSystemCommand: true))
            }
        } else {
            guard let url = URL(string: value) else {
                return false
            }

            if url.scheme?.hasPrefix("http") == true {
                NSWorkspace.shared.open(url)
            }
        }

        return true
    }
}
