//
//  BasicView.swift
//  Outlander
//
//  Created by Joseph McBride on 7/22/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa

class OView: NSView {
    var name: String = ""

    @IBInspectable var backgroundColor: NSColor? {
        didSet {
            needsDisplay = true
        }
    }

    @IBInspectable var borderColor: NSColor? = NSColor(hex: "#cccccc") {
        didSet {
            needsDisplay = true
        }
    }

    // dynamic allows for animation
    @IBInspectable dynamic var borderWidth: CGFloat = 0 {
        didSet {
            needsDisplay = true
        }
    }

    @IBInspectable dynamic var cornerRadius: CGFloat = 0 {
        didSet {
            needsDisplay = true
        }
    }

    @IBInspectable var displayBorder: Bool = true {
        didSet {
            needsDisplay = true
        }
    }

    override var wantsUpdateLayer: Bool {
        true
    }

    init() {
        super.init(frame: NSRect.zero)
    }

    init(color: NSColor, frame: NSRect) {
        super.init(frame: frame)
        backgroundColor = color
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    override var isFlipped: Bool {
        true
    }

    func reOrderView() {}

    func index(of key: String) -> Int {
        guard let idx = subviews.firstIndex(where: { view in
            (view as? OView)?.name == key
        }) else {
            return 0
        }

        return idx + 1
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
        layer.cornerRadius = cornerRadius

        if displayBorder {
            layer.borderColor = borderColor?.cgColor
            layer.borderWidth = borderWidth
        } else {
            layer.borderWidth = CGFloat.zero
        }
    }
}

public extension NSView {
    func removeAllConstraints() {
        var _superview = superview

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

        removeConstraints(constraints)
//        self.translatesAutoresizingMaskIntoConstraints = true
    }
}

enum MyStackViewOrientation {
    case horizontal
    case vertical
}

class MyStackView: OView {
    public var offset: CGFloat = 0

    public var stretchItems = false {
        didSet {
            needsLayout = true
        }
    }

    public var orientation: MyStackViewOrientation = .vertical {
        didSet {
            needsLayout = true
        }
    }

    public func append(_ view: NSView) {
        addSubview(view)
    }

    override func layout() {
        super.layout()

//        var offset: CGFloat = 0

        offset = 0

        for (_, view) in subviews.enumerated() {
            if let stacker = view as? MyStackView, stacker.needsLayout {
                stacker.layout()
                offset += stacker.offset
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

        var selfFrame = frame

        switch orientation {
        case .horizontal:
            selfFrame.origin.x = offset
        case .vertical:
            selfFrame.origin.y = offset
        }

        selfFrame.size.height = offset
        selfFrame.size.width = offset

        frame = selfFrame
    }
}

class VitalBarItemView: OView {
    public var text: String? {
        didSet {
            needsDisplay = true
        }
    }

    public var value: Double? {
        didSet {
            needsDisplay = true
        }
    }

    public var foregroundColor = NSColor.white {
        didSet {
            self.needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let text = text, let txt = NSString(utf8String: text) {
            let attributeDict: [NSAttributedString.Key: Any] = [
                .font: NSFont(name: "Menlo Bold", size: 11)!,
                .foregroundColor: foregroundColor,
            ]

            let size = txt.size(withAttributes: attributeDict)
            let point = NSPoint(
                x: (frame.size.width / 2) - (size.width / 2),
                y: (frame.size.height / 2) - (size.height / 2)
            )
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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }
}
