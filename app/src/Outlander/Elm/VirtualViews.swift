//
//  VirtualViews.swift
//  Outlander
//
//  Created by Joseph McBride on 7/21/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa

typealias Constraint = (_ child: NSView, _ parent: NSView) -> NSLayoutConstraint

indirect enum View<Message> {
    case _button(Button<Message>)
    case _textField(TextField<Message>)
    case _customLayout([(View<Message>, [Constraint])])

    func map<B>(_ transform: @escaping (Message) -> B) -> View<B> {
        switch self {
        case ._button(let b):
            return ._button(b.map(transform))
        case ._textField(let t):
            return ._textField(t.map(transform))
        case ._customLayout(let views):
            return ._customLayout(views.map { (v,c) in
                (v.map(transform), c)
            })
        }
    }
}

extension View {
    static func button(text: String, onClick: Message? = nil) -> View {
        return ._button(Button(text: text, onClick: onClick))
    }

    static func textField(text: String, onChange: ((String?) -> Message)? = nil, onEnd: ((String?) -> Message)? = nil) -> View {
        return ._textField(TextField(text: text, onChange: onChange, onEnd: onEnd))
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
        return Button<B>(text: text, onClick: onClick.map(transform))
    }
}

struct TextField<Message> {
    let text: String
    let onChange: ((String?) -> Message)?
    let onEnd: ((String?) -> Message)?
    
    
    init(text: String, onChange: ((String?) -> Message)? = nil, onEnd: ((String?) -> Message)? = nil) {
        self.text = text
        self.onChange = onChange
        self.onEnd = onEnd
    }
    
    func map<B>(_ transform: @escaping (Message) -> B) -> TextField<B> {
        return TextField<B>(text: text, onChange: onChange.map { x in { transform(x($0)) } }, onEnd: onEnd.map { x in { transform(x($0)) } })
    }
}
