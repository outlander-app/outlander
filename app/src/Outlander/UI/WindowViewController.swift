//
//  GameWindowViewController.swift
//  Outlander
//
//  Created by Joseph McBride on 12/7/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

class OLScrollView : NSScrollView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.verticalScroller?.scrollerStyle = .overlay
        self.horizontalScroller?.scrollerStyle = .overlay
    }

    override open var scrollerStyle: NSScroller.Style {
        get { return .overlay }
        set
        {
            self.verticalScroller?.scrollerStyle = .overlay
            self.horizontalScroller?.scrollerStyle = .overlay
        }
    }

    override var isFlipped: Bool {
        get { return true }
    }
}

class WindowViewController : NSViewController {
    @IBOutlet var mainView: OView!
    @IBOutlet var textView: NSTextView!

    public var gameContext: GameContext?
    public var name:String = ""
    public var visible:Bool = true
    public var closedTarget:String?
    
    private var foregroundNSColor: NSColor = WindowViewController.defaultFontColor

    public var borderColor: String =  "#cccccc" {
        didSet {
            self.mainView?.borderColor = NSColor(hex: self.borderColor) ?? WindowViewController.defaultFontColor
        }
    }

    public var borderWidth: CGFloat =  1 {
        didSet {
            self.mainView?.borderWidth = self.borderWidth
        }
    }
    
    public var foregroundColor: String = "#cccccc" {
        didSet {
            self.foregroundNSColor = NSColor(hex: self.foregroundColor) ?? WindowViewController.defaultFontColor
        }
    }

    public var backgroundColor: String = "#1e1e1e" {
        didSet {
            self.textView?.backgroundColor = NSColor(hex: self.backgroundColor) ?? WindowViewController.defaultBorderColor
        }
    }

    static var defaultFontColor = NSColor(hex: "#cccccc")!
    static var defaultFont = NSFont(name: "Helvetica", size: 14)!
    static var defaultMonoFont = NSFont(name: "Menlo", size: 13)!
    static var defaultCreatureColor = NSColor(hex: "#ffff00")!
    static var defaultBorderColor = NSColor(hex: "#1e1e1e")!

    var lastTag:TextTag?
    var queue: DispatchQueue?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTheme()

        self.textView.linkTextAttributes = [
            NSAttributedString.Key.foregroundColor: WindowViewController.defaultFontColor,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
            NSAttributedString.Key.cursor: NSCursor.pointingHand
        ]

        self.queue = DispatchQueue(label: "ol:\(self.name):window", qos: .userInteractive)
    }
    
    func updateTheme() {
        self.mainView?.backgroundColor = NSColor(hex: self.borderColor) ?? WindowViewController.defaultFontColor
        self.textView?.backgroundColor = NSColor(hex: self.backgroundColor) ?? WindowViewController.defaultBorderColor
    }

    func clear() {
        DispatchQueue.main.async {
            self.textView.string = ""
        }
    }

    func clearAndAppend(_ tags: [TextTag], highlightMonsters:Bool = false) {
        self.queue?.async {
            let target = NSMutableAttributedString()

            for tag in tags {
                let text = self.processSubs(tag.text)
                if let str = self.stringFromTag(tag, text: text) {
                    target.append(str)
                }
            }

            self.processHighlights(target, highlightMonsters: highlightMonsters)

//            self.queue?.sync(flags: .barrier) {
                self.setWithoutProcessing(target)
//            }
        }
    }

    func stringFromTag(_ tag: TextTag, text: String) -> NSMutableAttributedString? {
        
        guard let context = self.gameContext else {
            return nil
        }
        
        var foregroundColorToUse = self.foregroundNSColor
        var backgroundHex = tag.backgroundColor
        
        if tag.bold {
            if let value = context.presetFor("creatures") {
                foregroundColorToUse = NSColor(hex: value.color) ?? WindowViewController.defaultCreatureColor
            }
        }

        if let preset = tag.preset {
            if let value = context.presetFor(preset) {
                foregroundColorToUse = NSColor(hex: value.color) ?? self.foregroundNSColor
                backgroundHex = value.backgroundColor
            }
        }

        var font = WindowViewController.defaultFont
        if tag.mono {
            font = WindowViewController.defaultMonoFont
        }

        var attributes:[NSAttributedString.Key:Any] = [
            NSAttributedString.Key.foregroundColor: foregroundColorToUse,
            NSAttributedString.Key.font: font
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

    func processHighlights(_ text: NSMutableAttributedString, highlightMonsters:Bool = false) {
        guard let context = self.gameContext else {
            return
        }
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
            guard let regex = try? Regex(h.pattern) else {
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
                    range: range)

                if h.backgroundColor.count > 0 {
                    guard let bgColor = NSColor(hex: h.backgroundColor) else {
                        continue
                    }

                    text.addAttribute(
                        NSAttributedString.Key.backgroundColor,
                        value: bgColor,
                        range: range)
                }

                if h.soundFile.count > 0 {
                    context.events.sendCommand(Command2(command: "#play \(h.soundFile)", isSystemCommand: true))
                }
            }
        }
    }

    func processSubs(_ text: String) -> String {
        
        guard let context = self.gameContext else {
            return text
        }

        var result = text

        for sub in context.activeSubs() {
            guard let regex = try? Regex(sub.pattern, options: [.caseInsensitive]) else {
                continue
            }

            result = regex.replace(result, with: sub.action)
        }

        return result
    }

    func append(_ tag: TextTag) {
        self.queue?.async {
            if self.lastTag?.isPrompt == true && !tag.playerCommand {
                // skip multiple prompts of the same type
                if tag.isPrompt && self.lastTag?.text == tag.text {
                    return
                }

                self.appendWithoutProcessing(NSAttributedString(string: "\n"))
            }

            self.lastTag = tag

            let text = self.processSubs(tag.text)
            guard let str = self.stringFromTag(tag, text: text) else { return }
            self.processHighlights(str)

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
