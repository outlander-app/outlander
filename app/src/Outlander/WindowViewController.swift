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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func clear() {
        self.textView.string = ""
    }
    
    func append(_ tag: TextTag) {
        
        guard let context = self.gameContext else {
            return
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
        let str = NSAttributedString(string: tag.text, attributes: attributes)
        
        append(str)
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
}
