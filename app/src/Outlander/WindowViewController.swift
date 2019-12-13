//
//  GameWindowViewController.swift
//  Outlander
//
//  Created by Joseph McBride on 12/7/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

struct WindowSettings {
    var name:String
    var visible:Bool
    var closedTarget:String?
    
    var x:Int
    var y:Int
    var height:Int
    var width:Int
}

class OLScrollView : NSScrollView {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override open var scrollerStyle: NSScroller.Style {
        get { return .overlay }
        set { }
    }
}

class WindowViewController : NSViewController {
    @IBOutlet var textView: NSTextView!

    public var gameContext: GameContext?
    public var name:String = ""
    public var visible:Bool = true
    public var closedTarget:String?

    var defaultFont = NSFont(name: "Helvetica", size: 14)!
    var monoFont = NSFont(name: "Menlo", size: 13)!
    
    var lastTag:TextTag?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func clear() {
        DispatchQueue.main.async {
            self.textView.string = ""
        }
    }

    func clearAndAppend(_ tags: [TextTag]) {
        let target = NSMutableAttributedString()

        for tag in tags {
            if let str = stringFromTag(tag) {
                target.append(str)
            }
        }
        
        set(target)
    }
    
    func stringFromTag(_ tag: TextTag) -> NSAttributedString? {
        
        guard let context = self.gameContext else {
            return nil
        }
        
        var foregroundColor = NSColor.white
        
        if tag.bold {
            foregroundColor = NSColor(hex: context.presets["creatures"]!)!
        }
        
        if let preset = tag.preset {
            if let value = context.presets[preset] {
                foregroundColor = NSColor(hex: value) ?? foregroundColor
            }
        }
        
        var font = defaultFont
        if tag.mono {
            font = monoFont
        }
        
        let  attributes:[NSAttributedString.Key:Any] = [
            NSAttributedString.Key.foregroundColor: foregroundColor,
            NSAttributedString.Key.font: font
        ]

        return NSAttributedString(string: tag.text, attributes: attributes)
    }

    func append(_ tag: TextTag) {

        if self.lastTag?.isPrompt == true && !tag.playerCommand {
            // skip multiple prompts of the same type
            if tag.isPrompt && self.lastTag?.text == tag.text {
                return
            }
            
            // TODO: ignore highlights, etc.
            append(NSAttributedString(string: "\n"))
        }

        guard let str = stringFromTag(tag) else { return }

        append(str)

        self.lastTag = tag
    }

    func append(_ text: NSAttributedString) {
        DispatchQueue.main.async {
            let smartScroll = self.textView.visibleRect.maxY == self.textView.bounds.maxY
            
            self.textView.textStorage?.append(text)
            
            if smartScroll {
                self.textView.scrollToEndOfDocument(self)
            }
        }
    }

    func set(_ text: NSAttributedString) {
        DispatchQueue.main.async {
            let smartScroll = self.textView.visibleRect.maxY == self.textView.bounds.maxY

            self.textView.textStorage?.setAttributedString(text)
            
            if smartScroll {
                self.textView.scrollToEndOfDocument(self)
            }
        }
    }
}
