//
//  VirtualViews.swift
//  Outlander
//
//  Created by Joseph McBride on 7/21/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa
import Foundation

typealias Constraint = (_ child: NSView, _ parent: NSView) -> NSLayoutConstraint

indirect enum View<Message> {
    case _button(Button<Message>)
    case _textField(TextField<Message>)
    case _textView(TextView<Message>)
    case _stackView(StackView<Message>)
    case _vitalBarItem(VitalBarItem)
    case _customLayout([(View<Message>, [Constraint])])

    func map<B>(_ transform: @escaping (Message) -> B) -> View<B> {
        switch self {
        case let ._button(b):
            return ._button(b.map(transform))

        case let ._textField(t):
            return ._textField(t.map(transform))

        case let ._textView(t):
            return ._textView(t.map(transform))

        case let ._stackView(s):
            return ._stackView(s.map(transform))

        case let ._vitalBarItem(v):
            return ._vitalBarItem(v)

        case let ._customLayout(views):
            return ._customLayout(views.map { v, c in
                (v.map(transform), c)
            })
        }
    }
}

extension View {
    static func button(text: String, onClick: Message? = nil) -> View {
        ._button(Button(text: text, onClick: onClick))
    }

    static func textField(text: String, onChange: ((String) -> Message)? = nil, onEnd: ((String) -> Message)? = nil) -> View {
        ._textField(TextField(text: text, onChange: onChange, onEnd: onEnd))
    }

    static func textView(text: String) -> View {
        ._textView(TextView(text: text))
    }

    static func stackView(
        _ views: [View<Message>],
        axis: StackViewDirection = .vertical,
        backgroundColor: NSColor? = .white,
        distribution: NSStackView.Distribution = .fill,
        alignment: NSLayoutConstraint.Attribute = .top,
        spacing: Double = 5
    ) -> View {
        ._stackView(StackView(views: views, axis: axis, backgroundColor: backgroundColor, distribution: distribution, alignment: alignment, spacing: spacing))
    }

    static func vitalBarItem(_ text: String, value: Double, foreColor: NSColor = .white, backgroundColor: NSColor? = .red) -> View {
        ._vitalBarItem(VitalBarItem(text: text, value: value, foreColor: foreColor, backgroundColor: backgroundColor))
    }
}

struct Button<Message> {
    let text: String
    let onClick: Message?

    init(text: String, onClick: Message? = nil) {
        self.text = text
        self.onClick = onClick
    }

    func map<B>(_ transform: (Message) -> B) -> Button<B> {
        Button<B>(text: text, onClick: onClick.map(transform))
    }
}

struct TextField<Message> {
    let text: String
    let onChange: ((String) -> Message)?
    let onEnd: ((String) -> Message)?

    init(text: String, onChange: ((String) -> Message)? = nil, onEnd: ((String) -> Message)? = nil) {
        self.text = text
        self.onChange = onChange
        self.onEnd = onEnd
    }

    func map<B>(_ transform: @escaping (Message) -> B) -> TextField<B> {
        TextField<B>(text: text, onChange: onChange.map { x in { transform(x($0)) } }, onEnd: onEnd.map { x in { transform(x($0)) } })
    }
}

struct VitalBarItem {
    let text: String
    let value: Double
    let foreColor: NSColor
    let backgroundColor: NSColor?

    init(text: String, value: Double, foreColor: NSColor, backgroundColor: NSColor?) {
        self.text = text
        self.value = value
        self.foreColor = foreColor
        self.backgroundColor = backgroundColor
    }
}

enum StackViewDirection {
    case horizontal
    case vertical
}

struct StackView<Message> {
    let views: [View<Message>]
    let axis: StackViewDirection
    let backgroundColor: NSColor?
    let distribution: NSStackView.Distribution
    let alignment: NSLayoutConstraint.Attribute
    let spacing: Double

    init(views: [View<Message>],
         axis: StackViewDirection,
         backgroundColor: NSColor?,
         distribution: NSStackView.Distribution,
         alignment: NSLayoutConstraint.Attribute,
         spacing: Double) {
        self.views = views
        self.axis = axis
        self.backgroundColor = backgroundColor
        self.distribution = distribution
        self.alignment = alignment
        self.spacing = spacing
    }

    func map<B>(_ transform: @escaping (Message) -> B) -> StackView<B> {
        StackView<B>(views: views.map { view in view.map(transform) }, axis: axis, backgroundColor: backgroundColor, distribution: distribution, alignment: alignment, spacing: spacing)
    }
}

struct TextView<Message> {
    let text: String
//    let append: (String) -> ()

    func map<B>(_: @escaping (Message) -> B) -> TextView<B> {
        TextView<B>(text: text)
    }
}
