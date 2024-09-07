//
//  OView.swift
//  Outlander
//
//  Created by Joe McBride on 12/5/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

class OView: NSView {
    typealias OnPositionChanged = (CGPoint) -> Void

    private let resizableArea: CGFloat = 8
    private let borderPadding: CGFloat = 0
    private var draggedPoint: CGPoint = .zero
    private var minHeight: CGFloat = 100
    private var minWidth: CGFloat = 100

    var allowMove = false
    var name: String = ""
    var positionChanged: OnPositionChanged = { _ in }

//    @IBInspectable var backgroundColor: NSColor? {
//        didSet {
//            needsDisplay = true
//        }
//    }
//
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

//
//    @IBInspectable dynamic var cornerRadius: CGFloat = 0 {
//        didSet {
//            needsDisplay = true
//        }
//    }

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

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard allowMove else {
            return
        }
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard allowMove else {
            return
        }
        NSCursor.arrow.set()
    }

    private var isMouseDown = false
    private var isDragging = false
    override func mouseDown(with event: NSEvent) {
        guard allowMove else {
            super.mouseDown(with: event)
            return
        }

        isMouseDown = true

        let locationInView = convert(event.locationInWindow, from: nil)
        draggedPoint = locationInView
        NSCursor.closedHand.set()
    }

    override func mouseUp(with event: NSEvent) {
        guard allowMove else {
            super.mouseUp(with: event)
            return
        }

        isMouseDown = false
        isDragging = false

        draggedPoint = .zero
        NSCursor.arrow.set()
    }

    override func mouseMoved(with event: NSEvent) {
        guard allowMove else {
            super.mouseMoved(with: event)
            return
        }

        let locationInView = convert(event.locationInWindow, from: nil)
        cursorBorderPosition(locationInView)
    }

    override func mouseDragged(with event: NSEvent) {
        guard allowMove else {
            super.mouseDragged(with: event)
            return
        }

        isDragging = true

        let locationInView = convert(event.locationInWindow, from: nil)
        let horizontalDistanceDragged = locationInView.x - draggedPoint.x
        let verticalDistanceDragged = locationInView.y - draggedPoint.y
        let cursorPosition = cursorBorderPosition(draggedPoint)
        if cursorPosition != .none {
            let drag = CGPoint(x: horizontalDistanceDragged, y: verticalDistanceDragged)
            if checkIfBorder(cursorPosition, andDraggedOutward: drag) {
                return
            }
        }
        switch cursorPosition {
        case .top:
            size.height += verticalDistanceDragged
            draggedPoint = locationInView
        case .left:
            origin.x += horizontalDistanceDragged
            size.width = max(size.width - horizontalDistanceDragged, minWidth)
        case .bottom:
            origin.y += verticalDistanceDragged
            size.height = max(size.height - verticalDistanceDragged, minHeight)
        case .right:
            size.width += horizontalDistanceDragged
            draggedPoint = locationInView
        case .none:
            origin.x += locationInView.x - draggedPoint.x
            origin.y += locationInView.y - draggedPoint.y
            repositionView()
        }

        positionChanged(origin)
    }

    @discardableResult
    func cursorBorderPosition(_ locationInView: CGPoint) -> BorderPosition {
        if locationInView.x < resizableArea {
            NSCursor.resizeLeftRight.set()
            return .left
        } else if locationInView.x > bounds.width - resizableArea {
            NSCursor.resizeLeftRight.set()
            return .right
        } else if locationInView.y < resizableArea {
            NSCursor.resizeUpDown.set()
            return .bottom
        } else if locationInView.y > bounds.height - resizableArea {
            NSCursor.resizeUpDown.set()
            return .top
        } else {
            if isMouseDown && isDragging {
                NSCursor.closedHand.set()
            } else {
                NSCursor.arrow.set()
            }
            return .none
        }
    }

    enum BorderPosition {
        case top, left, bottom, right, none
    }

    private func checkIfBorder(_ border: BorderPosition,
                               andDraggedOutward drag: CGPoint) -> Bool
    {
        if border == .left, frame.minX <= borderPadding, drag.x < 0 {
            return true
        }
        if border == .bottom, frame.minY <= borderPadding, drag.y < 0 {
            return true
        }
        guard let superView = superview else { return false }
        if border == .right, frame.maxX >= superView.frame.maxX - borderPadding, drag.x > 0 {
            return true
        }
        if border == .top, frame.maxY >= superView.frame.maxY - borderPadding, drag.y > 0 {
            return true
        }
        return false
    }

    private func repositionView() {
        if frame.minX < borderPadding {
            origin.x = borderPadding
        }
        if frame.minY < borderPadding {
            origin.y = borderPadding
        }
        guard let superView = superview else { return }
        if frame.maxX > superView.frame.maxX - borderPadding {
            origin.x = superView.frame.maxX - frame.width - borderPadding
        }
        if frame.maxY > superView.frame.maxY - borderPadding {
            origin.y = superView.frame.maxY - frame.height - borderPadding
        }
    }
}

public extension NSView {
    @IBInspectable
    var backgroundColor: NSColor? {
        get {
            guard let color = layer?.backgroundColor else { return nil }
            return NSColor(cgColor: color)
        }
        set {
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
            needsDisplay = true
        }
    }

    var origin: CGPoint {
        get {
            frame.origin
        }
        set {
            frame.origin.x = newValue.x
            frame.origin.y = newValue.y
        }
    }

    var size: CGSize {
        get {
            frame.size
        }
        set {
            width = newValue.width
            height = newValue.height
        }
    }

    var width: CGFloat {
        get {
            frame.size.width
        }
        set {
            frame.size.width = newValue
        }
    }

    var height: CGFloat {
        get {
            frame.size.height
        }
        set {
            frame.size.height = newValue
        }
    }

    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            layer?.cornerRadius ?? 0
        }
        set {
            wantsLayer = true
            layer?.masksToBounds = true
            layer?.cornerRadius = abs(CGFloat(Int(newValue * 100)) / 100)
            needsDisplay = true
        }
    }

    @IBInspectable
    var shadowColor: NSColor? {
        get {
            guard let color = layer?.shadowColor else { return nil }
            return NSColor(cgColor: color)
        }
        set {
            wantsLayer = true
            layer?.shadowColor = newValue?.cgColor
            needsDisplay = true
        }
    }

    @IBInspectable
    var shadowOffset: CGSize {
        get {
            layer?.shadowOffset ?? CGSize.zero
        }
        set {
            wantsLayer = true
            layer?.shadowOffset = newValue
            needsDisplay = true
        }
    }

    @IBInspectable
    var shadowOpacity: Float {
        get {
            layer?.shadowOpacity ?? 0
        }
        set {
            wantsLayer = true
            layer?.shadowOpacity = newValue
            needsDisplay = true
        }
    }

    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            layer?.shadowRadius ?? 0
        }
        set {
            wantsLayer = true
            layer?.shadowRadius = newValue
            needsDisplay = true
        }
    }

    func addTrackingRect(_ rect: NSRect) {
        addTrackingArea(NSTrackingArea(
            rect: rect,
            options: [
                .mouseMoved,
                .mouseEnteredAndExited,
                .activeAlways,
            ],
            owner: self
        ))
    }
}
