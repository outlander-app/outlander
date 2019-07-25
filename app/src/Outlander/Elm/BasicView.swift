//
//  BasicView.swift
//  Outlander
//
//  Created by Joseph McBride on 7/22/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa

class OView : NSView {

    public var backgroundColor: NSColor?
    
    init() {
        super.init(frame: NSMakeRect(0, 0, 100, 100))
        self.autoresizingMask = [.height, .width]
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.autoresizingMask = [.height, .width]
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override var isFlipped: Bool {
        return true
    }
    
    override func draw(_ dirtyRect: NSRect) {

        if let bg = backgroundColor {
            bg.setFill()
        } else {
            NSColor.windowBackgroundColor.setFill()
        }

        self.bounds.fill()

        super.draw(dirtyRect)
    }
}
