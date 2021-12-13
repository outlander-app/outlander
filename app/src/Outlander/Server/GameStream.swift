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
        case let .text(text): return text == "\n" ? "eot" : "text"
        case let .tag(name, _, _):
            return name
        }
    }

    func hasAttr(_ key: String) -> Bool {
        attr(key) != nil
    }

    func attr(_ key: String) -> String? {
        switch self {
        case .text: return nil
        case let .tag(_, attrs, _):
            for attr in attrs {
                if attr.key == key {
                    return attr.value
                }
            }
            return nil
        }
    }

    func value(_ separator: String = ",") -> String? {
        switch self {
        case let .text(text): return text
        case let .tag(_, _, children):
            return children.compactMap { $0.value() }.joined(separator: separator)
        }
    }

    func children() -> [StreamToken] {
        switch self {
        case .text: return []
        case let .tag(_, _, children):
            return children
        }
    }

    func hasChildTag(_ tagName: String) -> Bool {
        switch self {
        case .text: return false
        case let .tag(_, _, children):
            return children.first(where: { s in s.name() == tagName }) != nil
        }
    }

    func monsters(_ ignore: Regex? = nil) -> [StreamToken] {
        switch self {
        case .text: return []
        case let .tag(_, _, children):
            return filterBetweenTags(children, start: "pushbold", end: "popbold", ignore: ignore)
        }
    }

    func filterBetweenTags(_ tokens: [StreamToken], start: String, end: String, ignore: Regex?) -> [StreamToken] {
        guard tokens.count > 0 else {
            return []
        }

        var results: [StreamToken] = []
        var capture = false

        for item in tokens {
            if item.name()?.lowercased() == start {
                capture = true
                continue
            } else if item.name()?.lowercased() == end {
                capture = false
                continue
            }

            let match = ignore?.hasMatches(item.value() ?? "") ?? false

            if capture, !match {
                results.append(item)
            }
        }

        return results
    }
}

protocol IReaderMode: AnyObject {
    func read(_ context: StreamContext) -> IReaderMode?
}

class ReaderBase<T> {
    private var modes: Stack<IReaderMode>

    init(target: T) {
        modes = Stack<IReaderMode>()
        self.target = target
    }

    public var target: T

    var current: IReaderMode? { modes.peek() }

    public func push(_ mode: IReaderMode) {
        modes.push(mode)
    }

    public func read(_ text: String) -> [StreamToken] {
        guard modes.hasItems() else { return [] }

        let context = StreamContext([], text: text[...])

        startNewMode(context)

        push(TextMode())

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

class GameStreamTokenizer: ReaderBase<[StreamToken]> {
    init() {
        super.init(target: [])
        push(TextMode())
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
            context.target.append(StreamToken.text(String(result)))
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
                appendTag(context)
                return nil
            }

            return nil

        case ">":
            context.text.consume(expecting: ">")

            // never treat tags after popStream as children
            if tagName == "popstream" {
                appendTag(context)
                return nil
            }

            children = readChildren(context)
            appendTag(context)
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

        guard TextMode().read(childContext) != nil else {
            return childContext.target
        }

        while !isClosingTagNext(childContext) {
            _ = TagMode().read(childContext)
            guard TextMode().read(childContext) != nil else {
                break
            }
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
           first == "<", second == "/"
        {
            return true
        }

        return false
    }

    func appendTag(_ context: StreamContext) {
        context.target.append(StreamToken.tag(name: tagName, attributes: attributes, children: children))
    }
}

protocol StringView: Collection, Equatable {
    static func string(_ elements: [Element]) -> String
    static func isSpace(_ element: Element) -> Bool
    static func isVariablePrefix(_ element: Element) -> Bool

    static var newline: Element { get }
    static var carriageReturn: Element { get }
    static var space: Element { get }
    static var tab: Element { get }
    static var quote: Element { get }
    static var tick: Element { get }
    static var backslash: Element { get }
    static var forwardslash: Element { get }
    static var equal: Element { get }
    static var rightBracket: Element { get }
    static var leftBracket: Element { get }
    static var rightBrace: Element { get }
    static var leftBrace: Element { get }
    static var greaterThan: Element { get }
    static var lessThan: Element { get }
    static var leftParen: Element { get }
    static var rightParen: Element { get }

    static var percent: Element { get }
    static var dollar: Element { get }

    static var exclamation: Element { get }
    static var and: Element { get }
    static var comma: Element { get }
    static var pipe: Element { get }
}

extension Substring: StringView {
    static func string(_ elements: [Character]) -> String {
        String(elements)
    }

    static func isSpace(_ element: Character) -> Bool {
        element == space || element == tab
    }

    static func isVariablePrefix(_ element: Element) -> Bool {
        element == dollar || element == percent || element == and
    }

    static let newline: Character = "\n"
    static let carriageReturn: Character = "\r"
    static let space: Character = " "
    static let tab: Character = "\t"
    static let quote: Character = "\""
    static let tick: Character = "'"
    static let backslash: Character = "\\"
    static let forwardslash: Character = "/"
    static let equal: Character = "="
    static let rightBracket: Character = "]"
    static let leftBracket: Character = "["
    static let rightBrace: Character = "}"
    static let leftBrace: Character = "{"
    static let greaterThan: Character = ">"
    static let lessThan: Character = "<"

    static var percent: Character = "%"
    static var dollar: Character = "$"

    static let leftParen: Character = "("
    static let rightParen: Character = ")"
    static let exclamation: Character = "!"
    static let and: Character = "&"
    static let pipe: Character = "|"
    static let comma: Character = ","
}

extension StringView where SubSequence == Self, Element: Equatable {
    var logicalCharacter: Bool {
        first == Self.pipe || first == Self.equal || first == Self.and
    }

    var second: Element? {
        let idx = index(after: startIndex)
        return self[idx]
    }

    @discardableResult
    mutating func consume(expecting char: Element) -> Bool {
        guard let f = first, f == char else { return false }
        removeFirst()
        return true
    }

    mutating func consume(while cond: (Element) -> Bool) {
        while let f = first, cond(f) {
            removeFirst()
        }
    }

    mutating func consumeWhitespace() {
        consume(while: { Self.isSpace($0) || $0 == Self.newline })
    }

    mutating func consumeSpaces() {
        consume(while: { Self.isSpace($0) })
    }

    mutating func parseToEnd() -> [Element] {
        parseMany(while: { _ in true })
    }

    mutating func parseWord() -> [Element] {
        parseMany(while: { !Self.isSpace($0) })
    }

    mutating func parseWords(while cond: (String) -> Bool) -> (String, String) {
        var results: [String] = []

        var word: String = ""

        while let _ = first {
            consumeSpaces()
            word = Self.string(parseWord())
            guard cond(word) else {
                break
            }
            results.append(word)
        }

        return (results.joined(separator: " "), word)
    }

    mutating func parseInt() -> Int? {
        let maybeNumber = parseMany(while: { !Self.isSpace($0) })
        return Int(Self.string(maybeNumber))
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

    mutating func parseToComponents() -> (String, Bool) {
        var result: [String] = []
        var current: [Element] = []
        var lastWord: String = ""
        var inQuote = false
        var previous: Element?

        while let c = first {
            if c == Self.leftBrace, !inQuote {
                break
            }

            if c == Self.quote, previous != Self.backslash {
                inQuote = !inQuote
            }

            if Self.isSpace(c), !inQuote {
                lastWord = Self.string(current)
                if lastWord == "then" {
                    current = []
                    break
                }
                result.append(lastWord)
                current = []
            } else {
                current.append(c)
            }

            previous = c
            removeFirst()
        }

        if current.count > 0 {
            lastWord = Self.string(current)
            if lastWord != "then" {
                result.append(Self.string(current))
            }
        }

        return (result.joined(separator: " "), lastWord == "then")
    }

    mutating func parseExpression() -> ScriptExpression? {
        var results: [ScriptExpression] = []
        while let _ = first {
            consumeSpaces()
            let identifier = Self.string(parseMany(while: { $0 != Self.leftParen && !Self.isSpace($0) && $0 != Self.exclamation }))

            if identifier.count == 0 {
                if consume(expecting: Self.leftParen) {
                    results.append(.value("("))
                }
                if consume(expecting: Self.exclamation) {
                    results.append(.value("!"))
                }
                continue
            }

            if first == Self.leftParen, identifier.first!.isLetter {
                // parse args
                consume(expecting: Self.leftParen)
                let args = parseFunctionArguments()
                consume(expecting: Self.rightParen)
                results.append(.function(identifier, args))
            } else {
                // spaces should be consumed on next pass...
                results.append(.value(identifier))
            }
        }

        let combined = ScriptExpression.combine(expressions: results)

        if combined.count == 1 {
            return combined[0]
        }

        return combined.count > 0 ? .values(combined) : nil
    }

    mutating func parseFunctionArguments() -> [String] {
        var results: [String] = []
        var current: [Element] = []

        while let c = first, c != Self.rightParen {
            switch c {
            case Self.comma:
                results.append(Self.string(current).trimmingCharacters(in: .whitespaces))
                current = []
                _ = popFirst()
            case Self.quote:
                current.append(c)
                _ = popFirst()
                current = current + parseMany({ $0.parseQuotedCharacter(dropslash: false) }, while: { $0 != Self.quote })
                current.append(Self.quote)
                _ = popFirst()
            default:
                current.append(c)
                _ = popFirst()
            }
        }

        if current.count > 0 {
            results.append(Self.string(current).trimmingCharacters(in: .whitespaces))
        }

        return results
    }

    mutating func parseAttribute(_ tagName: String? = nil) -> Attribute? {
        let key = Self.string(parseMany(while: { $0 != Self.equal }))

        guard key.count > 0 else { return nil }

        consume(expecting: Self.equal)
        guard let delimiter = popFirst() else { return nil }

        var value: [Element]

        if key == "subtitle", tagName == "streamwindow" {
            value = parseMany({ $0.parseQuotedCharacter() }, while: { $0 != Self.rightBracket })
            value.append(Self.rightBracket)
            consume(expecting: Self.rightBracket)
        } else {
            value = parseMany({ $0.parseQuotedCharacter() }, while: { $0 != delimiter })
        }

        consume(expecting: delimiter)

        return Attribute(key: key, value: Self.string(value))
    }

    mutating func parseAttributes(_ tagName: String? = nil) -> [Attribute] {
        var attributes: [Attribute] = []

        consumeSpaces()

        while let f = first, f != Self.greaterThan, f != Self.forwardslash {
            if let attr = parseAttribute(tagName) {
                attributes.append(attr)
            }
            consumeSpaces()
        }

        return attributes
    }

    mutating func parseQuotedCharacter(dropslash: Bool = true) -> Element? {
        guard let c = popFirst() else { return nil }

        switch c {
        case Self.backslash:
            guard dropslash else {
                return c
            }
            return popFirst()
        case Self.carriageReturn:
            return popFirst()
        default:
            return c
        }
    }
}

struct TextTag {
    var text: String
    var window: String
    var color: String?
    var backgroundColor: String?
    var href: String?
    var command: String?
    var mono: Bool = false
    var bold: Bool = false
    var isPrompt: Bool = false
    var preset: String?
    var playerCommand: Bool = false

    func canCombine(with tag: TextTag) -> Bool {
        guard window == tag.window else { return false }
        guard isPrompt == tag.isPrompt else { return false }
        guard mono == tag.mono else { return false }
        guard bold == tag.bold else { return false }
        guard preset == tag.preset else { return false }
        guard color == tag.color else { return false }
        guard backgroundColor == tag.backgroundColor else { return false }
        guard href == tag.href else { return false }
        guard command == tag.command else { return false }
        guard playerCommand == tag.playerCommand else { return false }

        return true
    }

    func combine(_ tag: TextTag) -> [TextTag] {
        guard canCombine(with: tag) else { return [self, tag] }

        return [TextTag(
            text: text + tag.text,
            window: window,
            color: color,
            backgroundColor: backgroundColor,
            href: href,
            command: command,
            mono: mono,
            bold: bold,
            preset: preset
        )]
    }

    static func tagFor(_ text: String, window: String = "", mono: Bool = false, color: String? = nil, preset: String? = nil, playerCommand: Bool = false) -> TextTag {
        TextTag(text: text, window: window, color: color, mono: mono, preset: preset, playerCommand: playerCommand)
    }

    static func combine(tags: [TextTag]) -> [TextTag] {
        let combined = tags.reduce([TextTag]()) { list, next in

            if let last = list.last {
                return list.dropLast() + last.combine(next)
            }

            return [next]
        }

        return combined
    }

    static func lines(tags: [TextTag]) -> [String] {
        let combined = tags.map { $0.text }.joined(separator: "").components(separatedBy: "\n").filter { !$0.isEmpty }
        return combined
    }
}

enum StreamCommand: CustomStringConvertible {
    case text([TextTag])
    case clearStream(String)
    case createWindow(name: String, title: String, closedTarget: String?)
    case vitals(name: String, value: Int)
    case launchUrl(String)
    case spell(String)
    case roundtime(Date)
    case room
    case compass([String: String])
    case hands(String, String)
    case character(String, String)
    case indicator(String, Bool)
    case prompt(String)

    var description: String {
        switch self {
        case .text:
            return "text"
        case .clearStream:
            return "clearStream"
        case .createWindow:
            return "createWindow"
        case .vitals:
            return "vitals"
        case .launchUrl:
            return "launchUrl"
        case .spell:
            return "spell"
        case .roundtime:
            return "roundtime"
        case .room:
            return "room"
        case .compass:
            return "compass"
        case .hands:
            return "hands"
        case .character:
            return "character"
        case .indicator:
            return "indicator"
        case .prompt:
            return "prompt"
        }
    }
}

class GameStream {
    var tokenizer: GameStreamTokenizer
    var context: GameContext

    private var isSetup = false
    private var inStream = false
    private var lastStreamId = ""
    private var ignoreNextEot = false

    private var mono = false
    private var bold = false

    private var lastToken: StreamToken?

    private var streamCommands: (StreamCommand) -> Void

    private var tags: [TextTag] = []

    private var handlers: [StreamHandler] = []

    private let ignoredEot = [
        "app",
        "clearstream",
        "compass",
        "compdef",
        "component",
        "dialogdata",
        "endsetup",
        "exposecontainer",
        "indicator",
        "left",
        "mode",
        "opendialog",
        "nav",
        "output",
        "right",
        "streamwindow",
        "spell",
        "switchquickbar",
    ]

    private let ignoreNextEotList = [
        "experience",
        "inv",
        "popstream",
        "room",
    ]

    private let roomTags = [
        "roomdesc",
        "roomobjs",
        "roomplayers",
        "roomexits",
        "roomextra",
    ]

    private let compassMap = [
        "n": "north",
        "s": "south",
        "e": "east",
        "w": "west",
        "ne": "northeast",
        "nw": "northwest",
        "se": "southeast",
        "sw": "southwest",
        "up": "up",
        "down": "down",
        "out": "out",
    ]

    var monsterCountIgnoreList: String = "" {
        didSet {
            if !monsterCountIgnoreList.isEmpty {
                monsterCountIgnoreRegex = try? Regex(monsterCountIgnoreList)
            }
        }
    }

    var monsterCountIgnoreRegex: Regex?

    init(context: GameContext, streamCommands: @escaping (StreamCommand) -> Void) {
        self.context = context
        self.streamCommands = streamCommands
        tokenizer = GameStreamTokenizer()

        handlers.append(TriggerHandler())
    }

    func addHandler(_ handler: StreamHandler) {
        handlers.append(handler)
    }

    public func reset(_ isSetup: Bool = false) {
        self.isSetup = isSetup

        inStream = false
        lastStreamId = ""
        ignoreNextEot = false

        mono = false
        bold = false

        lastToken = nil
        tags = []
    }

    public func stream(_ data: Data) {
        stream(String(data: data, encoding: .utf8) ?? "")
    }

    public func stream(_ data: String) {
        let rawTag = TextTag.tagFor(data, window: "raw", mono: true)
        streamCommands(.text([rawTag]))

        let tokens = tokenizer.read(data.replacingOccurrences(of: "\r\n", with: "\n"))

        for token in tokens {
            processToken(token)

            if let tag = tagForToken(token) {
                let isPrompt = token.name() == "prompt"

                if isPrompt && tags.count == 0 { return }

                tags.append(tag)

                if !isSetup || isPrompt {
                    let combined = TextTag.combine(tags: tags)
                    streamCommands(.text(combined))
                    tags.removeAll()

                    for line in TextTag.lines(tags: combined) {
                        sendToHandlers(text: line)
                    }
                }
            }
        }
    }

    public func sendToHandlers(text: String) {
        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }

        for line in lines {
            for handler in handlers {
                handler.stream(line, with: context)
            }
        }
    }

    func processToken(_ token: StreamToken) {
        guard case let .tag(tagName, _, children) = token else { return }

        switch tagName {
        case "prompt":
            let promptValue = token.value()?.replacingOccurrences(of: "&gt;", with: ">") ?? ""

            context.globalVars["prompt"] = promptValue
            context.globalVars["gametime"] = token.attr("time") ?? ""

            let today = Date().timeIntervalSince1970
            context.globalVars["gametimeupdate"] = "\(today)"
            streamCommands(.prompt(promptValue))

        case "roundtime":
            if let num = Int(token.attr("value") ?? "") {
                let rt = Date(timeIntervalSince1970: TimeInterval(num))
                streamCommands(.roundtime(rt))
            }

        case "left":
            context.globalVars["lefthand"] = token.value() ?? "Empty"
            context.globalVars["lefthandnoun"] = token.attr("noun") ?? ""
            context.globalVars["lefthandid"] = token.attr("exist") ?? ""

            streamCommands(.hands(
                context.globalVars["lefthand"] ?? "Empty",
                context.globalVars["righthand"] ?? "Empty"
            ))

        case "right":
            context.globalVars["righthand"] = token.value() ?? "Empty"
            context.globalVars["righthandnoun"] = token.attr("noun") ?? ""
            context.globalVars["righthandid"] = token.attr("exist") ?? ""

            streamCommands(.hands(
                context.globalVars["lefthand"] ?? "Empty",
                context.globalVars["righthand"] ?? "Empty"
            ))

        case "spell":
            if let spell = token.value() {
                context.globalVars["preparedspell"] = spell
                streamCommands(.spell(spell))
            }

        case "pushbold":
            bold = true

        case "popbold":
            bold = false

        case "clearstream":
            if let id = token.attr("id") {
                streamCommands(.clearStream(id.lowercased()))
            }

        case "pushstream":
            inStream = true
            if let id = token.attr("id") {
                lastStreamId = id.lowercased()
            }

        case "popstream":
            ignoreNextEot = ignoreNextEotList.contains(lastStreamId)
            inStream = false
            lastStreamId = ""

        case "streamwindow":
            let id = token.attr("id")
            let subtitle = token.attr("subtitle")

            if id == "main", subtitle != nil, subtitle!.count > 3 {
                context.globalVars["roomtitle"] = String(subtitle!.dropFirst(3))
            }

            if !isSetup, let win = id {
                let closedTarget = token.attr("ifClosed")?.count == 0 ? nil : token.attr("ifClosed")
                streamCommands(.createWindow(name: win, title: token.attr("title") ?? "", closedTarget: closedTarget))
            }

        case "component":
            guard var id = token.attr("id") else { return }

            if !id.hasPrefix("exp") {
                id = id.replacingOccurrences(of: " ", with: "")

                let value = token.value("") ?? ""
                context.globalVars[id] = value

                if id == "roomobjs" {
                    let monsters = token.monsters(monsterCountIgnoreRegex)
                    context.globalVars["monsterlist"] = monsters.map { t in t.value() ?? "" }.joined(separator: "|")
                    context.globalVars["monstercount"] = "\(monsters.count)"
                }

                if roomTags.contains(id) {
                    streamCommands(.room)
                }
            }

        case "compass":
            let directions = token.children().filter { $0.name() == "dir" && $0.hasAttr("value") }

            var found: [String] = []
            var settings: [String: String] = [:]

            for dir in directions {
                let mapped = compassMap[dir.attr("value")!]!
                found.append(mapped)
                settings[mapped] = "1"
            }

            let notFound = compassMap.values.filter { !found.contains($0) }

            for dir in notFound {
                settings[dir] = "0"
            }

            for (key, value) in settings {
                context.globalVars[key] = value
            }

            streamCommands(.compass(settings))

        case "indicator":
            let id = token.attr("id")?.dropFirst(4).lowercased() ?? ""
            let visible = token.attr("visible")?.lowercased() == "y" ? "1" : "0"

            guard id.count > 0 else { break }

            context.globalVars[id] = visible
            streamCommands(.indicator(id, visible == "1"))

        case "dialogdata":
            let vitals = children.filter { $0.name() == "progressbar" && $0.hasAttr("id") }

            for vital in vitals {
                let name = vital.attr("id") ?? ""
                let value = vital.attr("value") ?? "0"

                guard name.count > 0 else { continue }

                context.globalVars[name] = value
                streamCommands(.vitals(name: name, value: Int(value)!))
            }

        case "app":
            let characterName = token.attr("char") ?? ""
            let game = token.attr("game") ?? ""
            context.globalVars["charactername"] = characterName
            context.globalVars["game"] = game
            streamCommands(.character(game, characterName))

        case "launchurl":
            if let url = token.attr("src") {
                streamCommands(.launchUrl(url))
            }

        case "endsetup":
            isSetup = true

        default:
            return
        }
    }

    func tagForToken(_ token: StreamToken) -> TextTag? {
        var tag: TextTag?

        switch token.name() {
        case "text":
            tag = createTag(token)
            tag?.window = lastStreamId

            if inStream, lastStreamId == "logons" || lastStreamId == "death" {
                let trimmed = tag?.text.trimmingCharacters(in: .whitespaces) ?? ""
                tag?.text = trimmed
            }

            if lastToken?.name() == "preset", tag!.text.count > 0, tag!.text.hasPrefix("  You also see") {
                tag?.preset = lastToken?.attr("id")
                let text = "\n\(tag!.text.dropFirst(2))"
                tag?.text = text
            }

            if lastToken?.name() == "style", lastToken?.attr("id") == "roomName" {
                tag?.preset = "roomname"
            }

        case "eot":
            guard let tokenName = lastToken?.name(), !self.ignoredEot.contains(tokenName) else {
                break
            }
            guard !inStream || lastStreamId == "combat" else { break }
            guard tokenName != "prompt" else { break }

            guard !ignoreNextEot else {
                ignoreNextEot = false
                break
            }

            tag = TextTag(text: "\n", window: lastStreamId == "combat" ? "combat" : "")

        case "prompt":
            tag = createTag(token)
            tag?.isPrompt = true

        case "output":
            if let style = token.attr("class") {
                if style == "mono" {
                    mono = true
                } else {
                    mono = false
                }
            }

        case "a":
            tag = createTag(token)
            tag?.href = token.attr("href")

            if inStream {
                tag?.window = lastStreamId
            }

        case "b":
            // <b>You yell,</b> Hogs!
            tag = createTag(token)

            if inStream {
                tag?.bold = true
                tag?.window = lastStreamId
            }

        case "d":
            guard case let .tag(_, _, children) = token else { break }

            if children.count > 0 {
                if children[0].name() == "b" || children[0].name() == "text" {
                    tag = createTag(children[0])
                }

            } else {
                tag = createTag(token)
            }

            if let cmd = token.attr("cmd") {
                tag?.command = cmd
            }

            if inStream {
                tag?.window = lastStreamId
            }

        case "preset":
            tag = createTag(token)
            tag?.window = lastStreamId
            tag?.preset = token.attr("id")?.lowercased()

        default:
            tag = nil
        }

        lastToken = token

        return tag
    }

    func createTag(_ token: StreamToken) -> TextTag {
        var text = token.value() ?? ""
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&amp;", with: "&")

        var tag = TextTag.tagFor(text)

        tag.bold = bold
        tag.mono = mono

        return tag
    }
}
