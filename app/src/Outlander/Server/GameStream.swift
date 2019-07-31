//
//  Tokenizer.swift
//  Outlander
//
//  Created by Joseph McBride on 7/29/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

struct Attribute {
    var key: String
    var value: String
}

enum StreamToken {
    indirect case tag(name: String, attributes: [Attribute], children: [StreamToken])
    case text(String)
}

extension StreamToken {

    func name() -> String? {
        switch self {
        case .text: return nil
        case .tag(let name, _, _):
            return name
        }
    }

    func hasAttr(_ key:String) -> Bool {
        return attr(key) != nil
    }

    func attr(_ key:String) -> String? {
        switch self {
        case .text: return nil
        case .tag(_, let attrs, _):
            for attr in attrs {
                if attr.key == key {
                    return attr.value
                }
            }
            return nil
        }
    }

    func value() -> String? {
        switch self {
        case .text(let text): return text
        case .tag(_, _, let children):
            return children.compactMap({$0.value()}).joined(separator: ",")
        }
    }
}

protocol IReaderMode: class {
    func read(_ context: StreamContext) -> IReaderMode?
}

class ReaderBase<T> {
    private var modes: Stack<IReaderMode>

    init(target: T) {
        modes = Stack<IReaderMode>()
        self.target = target
    }

    public var target: T

    var current: IReaderMode? {
        get { return modes.peek() }
    }

    public func push(_ mode: IReaderMode) {
        modes.push(mode)
    }

    public func read(_ text: String) -> [StreamToken] {

        guard modes.hasItems() else { return [] }

        let context = StreamContext([], text: text[...])
        
        startNewMode(context)
        
        return context.target
    }

    func startNewMode(_ context: StreamContext) {
        guard modes.hasItems() else { return }
        
        let next = current?.read(context)

        guard let nextMode = next else {
            _ = modes.pop()
            startNewMode(context)
            return
        }

        if nextMode !== current {
            modes.push(nextMode)
            startNewMode(context)
        }
    }
}

class GameStreamTokenizer : ReaderBase<[StreamToken]> {
    init() {
        super.init(target: [])
        self.push(TextMode())
    }
}

class StreamContext {
    var text: String.SubSequence
    var target: [StreamToken]

    init(_ target: [StreamToken], text: String.SubSequence) {
        self.target = target
        self.text = text
    }
}

class TextMode: IReaderMode {
    func read(_ context: StreamContext) -> IReaderMode? {

        let result = context.text.parseMany(while: { $0 != "<" })
        if result.count > 0 {
            context.target.append( StreamToken.text(String(result)) )
        }

        guard context.text.first != nil else {
            return nil
        }

        return TagMode()
    }
}

class TagMode: IReaderMode {
    var tagName: String = ""
    var children: [StreamToken] = []
    var attributes: [Attribute] = []

    func read(_ context: StreamContext) -> IReaderMode? {
        
        context.text.consume(expecting: "<")

        let result = context.text.parseMany(while: { $0 != "/" && $0 != ">" && $0 != " " })
        tagName = String(result).lowercased()

        return readNext(context)
    }

    func readNext(_ context: StreamContext) -> IReaderMode? {
        guard let f = context.text.first else { return nil }

        switch f {
        case "/":
            context.text.consume(expecting: "/")
            guard let f2 = context.text.first, f2 != ">" else {
                // consume self closing tag
                context.text.consume(expecting: ">")
                self.appendTag(context)
                return nil
            }

            return nil

        case ">":
            context.text.consume(expecting: ">")
            children = readChildren(context)
            self.appendTag(context)
            return nil
        case " ":
            attributes = context.text.parseAttributes(tagName)
            return readNext(context)
        default:
            return nil
        }
    }

    func readChildren(_ context: StreamContext) -> [StreamToken] {
        let childContext = StreamContext([], text: context.text)

        _ = TextMode().read(childContext)

        while !isClosingTagNext(childContext) {
            _ = TagMode().read(childContext)
        }

        context.text = childContext.text

        consumeClosingTag(context)
        
        return childContext.target
    }

    func consumeClosingTag(_ context: StreamContext) {
        context.text.consume(while: { $0 != ">" })
        context.text.consume(expecting: ">")
    }

    func isClosingTagNext(_ context: StreamContext) -> Bool {
        if let first = context.text.first,
           let second = context.text.second,
              first == "<" && second == "/" {
            return true
        }
        return false
    }

    func appendTag(_ context: StreamContext) {
        context.target.append( StreamToken.tag(name: tagName, attributes: attributes, children: children) )
    }
}

protocol StringView : Collection {
    static func string(_ elements: [Element]) -> String

    static var newline: Element { get }
    static var space: Element { get }
    static var quote: Element { get }
    static var tick: Element { get }
    static var backslash: Element { get }
    static var forwardslash: Element { get }
    static var equal: Element { get }
    static var rightBracket: Element { get }
    static var greaterThan: Element { get }
    static var lessThan: Element { get }
}

extension Substring : StringView {
    static func string(_ elements: [Character]) -> String {
        return String(elements)
    }

    static let newline: Character  = "\n"
    static let space: Character = " "
    static let quote: Character = "\""
    static let tick: Character = "'"
    static let backslash: Character = "\\"
    static let forwardslash: Character = "/"
    static let equal: Character = "="
    static let rightBracket: Character = "]"
    static let greaterThan: Character = ">"
    static let lessThan: Character = "<"
}

extension StringView where SubSequence == Self, Element: Equatable {

    var second: Element? {
        get {
            let idx = self.index(after: self.startIndex)
            return self[idx]
        }
    }

    mutating func consume(expecting char: Element) {
        guard let f = first, f == char else { return }
        removeFirst()
    }

    mutating func consume(while cond: (Element) -> Bool) {
        while let f = first, cond(f) {
            removeFirst()
        }
    }

    mutating func parseMany(while cond: (Element) -> Bool) -> [Element] {
        var result: [Element] = []
        while let c = first, cond(c) {
            result.append(c)
            removeFirst()
        }
        return result
    }

    mutating func parseMany<A>(_ f: (inout Self) -> A?, while cond: (Element) -> Bool) -> [A] {
        var result: [A] = []
        while let c = first, cond(c), let next = f(&self) {
            result.append(next)
        }
        return result
    }

    mutating func parseAttribute(_ tagName:String? = nil) -> Attribute? {
        let key = Self.string(parseMany(while: { $0 != Self.equal }))

        guard key.count > 0 else { return nil }

        consume(expecting: Self.equal)
        guard let delimiter = popFirst() else { return nil }
        
        var value:[Element]

        if key == "subtitle" && tagName == "streamwindow" {
            value = parseMany({ $0.parseQuotedCharacter() }, while: { $0 != Self.rightBracket })
            value.append(Self.rightBracket)
            consume(expecting: Self.rightBracket)
        }
        else {
            value = parseMany({ $0.parseQuotedCharacter() }, while: { $0 != delimiter })
        }
        
        consume(expecting: delimiter)

        return Attribute(key: key, value: Self.string(value))
    }

    mutating func parseAttributes(_ tagName:String? = nil) -> [Attribute] {
        var attributes: [Attribute] = []
        
        consume(while: { $0 == Self.space })

        while let f = first, f != Self.greaterThan && f != Self.forwardslash {
            if let attr = parseAttribute(tagName) {
                attributes.append(attr)
            }
            consume(while: { $0 == Self.space })
        }
        
        return attributes
    }

    mutating func parseQuotedCharacter() -> Element? {
        guard let c = popFirst() else { return nil }

        switch c {
        case Self.backslash:
            return popFirst()
        default:
            return c
        }
    }
}

class GameStream {
    var tokenizer: GameStreamTokenizer

    init() {
        tokenizer = GameStreamTokenizer()
    }

    public func stream(_ data: Data) {
    }

    public func stream(_ data: String) {
        let tokens = tokenizer.read(data)
        for token in tokens {
            print(token.value())
        }
    }
}
