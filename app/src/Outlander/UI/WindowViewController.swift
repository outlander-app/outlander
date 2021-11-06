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

class WindowViewController: NSViewController {
    @IBOutlet var mainView: OView!
    @IBOutlet var textView: NSTextView!

    public var gameContext: GameContext?
    public var name: String = ""
    public var visible: Bool = true
    public var closedTarget: String?

    private var foregroundNSColor: NSColor = WindowViewController.defaultFontColor

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
        updateTheme()

        textView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: WindowViewController.defaultFontColor,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
            NSAttributedString.Key.cursor: NSCursor.pointingHand,
        ]

        queue = DispatchQueue(label: "ol:\(name):window", qos: .userInteractive)
    }

    func updateTheme() {
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

            for tag in tags {
                let text = self.processSubs(tag.text)
                if let str = self.stringFromTag(tag, text: text) {
                    target.append(str)
                }
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

        var font = WindowViewController.defaultFont
        if tag.mono {
            font = WindowViewController.defaultMonoFont
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

            let text = self.processSubs(tag.text)
            guard let str = self.stringFromTag(tag, text: text) else { return }
            self.processHighlights(str, context: context)

            self.appendWithoutProcessing(str)
        }
    }

    func appendWithoutProcessing(_ text: NSAttributedString) {
        // DO NOT add highlights, etc.
//        self.queue?.sync(flags: .barrier) {
        DispatchQueue.main.async {
            let smartScroll = self.textView.visibleRect.maxY == self.textView.bounds.maxY

            self.textView.textStorage?.append(text)

            if smartScroll {
                self.textView.scrollToEndOfDocument(self)
            }
        }
//        }
    }

    func setWithoutProcessing(_ text: NSMutableAttributedString) {
        // DO NOT add highlights, etc.
        DispatchQueue.main.async {
            let smartScroll = self.textView.visibleRect.maxY == self.textView.bounds.maxY

            self.textView.textStorage?.setAttributedString(text)

            if smartScroll {
                self.textView.scrollToEndOfDocument(self)
            }
        }
    }
}
