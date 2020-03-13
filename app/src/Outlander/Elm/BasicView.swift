//
//  BasicView.swift
//  Outlander
//
//  Created by Joseph McBride on 7/22/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa

class OView : NSView {
    @IBInspectable var backgroundColor: NSColor? {
        didSet {
            self.needsDisplay = true
        }
    }

    @IBInspectable var borderColor: NSColor? = NSColor(hex: "#cccccc") {
        didSet {
            self.needsDisplay = true
        }
    }

    // dynamic allows for animation
    @IBInspectable dynamic var borderWidth: CGFloat = 0 {
        didSet {
            self.needsDisplay = true
        }
    }
    
    @IBInspectable dynamic var cornerRadius: CGFloat = 0 {
        didSet {
            self.needsDisplay = true
        }
    }

    override var wantsUpdateLayer: Bool {
        return true
    }

    init() {
        super.init(frame: NSRect.zero)
    }

    init(color: NSColor, frame: NSRect) {
        super.init(frame: frame)
        self.backgroundColor = color
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override var isFlipped: Bool {
        return true
    }
    
    override func animation(forKey key: NSAnimatablePropertyKey) -> Any? {
        switch key {
        case "borderWidth":
            return CABasicAnimation()
        default:
            return super.animation(forKey: key)
        }
    }

    override func updateLayer() {
        guard let layer = layer else { return }
        
        layer.backgroundColor = backgroundColor?.cgColor
        layer.borderColor = borderColor?.cgColor
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
    }
}

extension NSView {

    public func removeAllConstraints() {
        var _superview = self.superview

        while let superview = _superview {
            for constraint in superview.constraints {

                if let first = constraint.firstItem as? NSView, first == self {
                    superview.removeConstraint(constraint)
                }

                if let second = constraint.secondItem as? NSView, second == self {
                    superview.removeConstraint(constraint)
                }
            }

            _superview = superview.superview
        }

        self.removeConstraints(self.constraints)
//        self.translatesAutoresizingMaskIntoConstraints = true
    }
}

enum MyStackViewOrientation {
    case horizontal
    case vertical
}

class MyStackView : OView {
    
    public var offset: CGFloat = 0

    public var stretchItems = false {
        didSet {
            self.needsLayout = true
        }
    }

    public var orientation: MyStackViewOrientation = .vertical {
        didSet {
            self.needsLayout = true
        }
    }

    public func append(_ view: NSView) {
        self.addSubview(view)
    }
    
    override func layout() {
        super.layout()

//        var offset: CGFloat = 0
        
        self.offset = 0

        for (_, view) in self.subviews.enumerated() {

            if let stacker = view as? MyStackView, stacker.needsLayout {
                stacker.layout()
                self.offset += stacker.offset
            }

            var frame = view.frame

            switch orientation {
            case .horizontal:
                frame.origin.x = offset
            case .vertical:
                frame.origin.y = offset
            }

            view.frame = frame

            switch orientation {
            case .horizontal:
                offset += view.frame.maxX

            case .vertical:
                offset += view.frame.maxY
            }

            if stretchItems {
                view.removeAllConstraints()

//                switch orientation {
//                case .horizontal:
//                    activate(
//                        view.anchor.top.bottom
//                    )
//                case .vertical:
//                    activate(
//                        view.anchor.left.right
//                    )
//                }
            }
        }

        var selfFrame = self.frame

        switch orientation {
        case .horizontal:
            selfFrame.origin.x = offset
        case .vertical:
            selfFrame.origin.y = offset
        }

        selfFrame.size.height = offset
        selfFrame.size.width = offset

        self.frame = selfFrame
    }
}

class VitalBarItemView : OView {

    public var text: String? {
        didSet {
            self.needsDisplay = true
        }
    }

    public var value: Double? {
       didSet {
           self.needsDisplay = true
       }
   }

    public var foregroundColor: NSColor = NSColor.white {
       didSet {
           self.needsDisplay = true
       }
   }

    override func draw(_ dirtyRect: NSRect) {

        super.draw(dirtyRect)

        if let text = self.text, let txt = NSString(utf8String: text) {
            let attributeDict: [NSAttributedString.Key : Any] = [
                .font: NSFont.init(name: "Menlo Bold", size: 11)!,
                .foregroundColor: self.foregroundColor,
            ]

            let size = txt.size(withAttributes: attributeDict)
            let point = NSPoint(
                x: (self.frame.size.width / 2) - (size.width / 2),
                y: (self.frame.size.height / 2) - (size.height / 2))
            txt.draw(at: point, withAttributes: attributeDict)
        }
    }
}

class ScrollableTextView: NSView {
    let scrollView = NSScrollView()
    var textView: NSTextView
    var textStorage: NSTextStorage

    override init(frame frameRect: NSRect) {
        
//        let height = 500
        let height = CGFloat.greatestFiniteMagnitude

        let rect = CGRect(
            x: 0, y: 0,
            width: 0, height: height
        )

        let layoutManager = NSLayoutManager()
        
        textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(size: rect.size)
        layoutManager.addTextContainer(textContainer)
        textView = NSTextView(frame: rect, textContainer: textContainer)

        super.init(frame: frameRect)

        textView.maxSize = NSSize(width: 0, height: height)

        textContainer.heightTracksTextView = false
        textContainer.widthTracksTextView = true

        textView.isRichText = false
        textView.importsGraphics = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.textColor = NSColor.white
//        textView.font = R.font.text
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false

        addSubview(scrollView)
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.drawsBackground = true
        textView.drawsBackground = true
//        scrollView.scrollerStyle = .legacy

//        activate(
//            scrollView.anchor.edges
//        )

        scrollView.documentView = textView
        textView.autoresizingMask = [.width]
    }

    required init?(coder decoder: NSCoder) {
        fatalError()
    }
}
