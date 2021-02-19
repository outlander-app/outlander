//
//  Parser.swift
//  Outlander
//
//  Created by Joseph McBride on 7/17/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

public struct ScriptParseError: Error, Hashable {
    public enum Reason: Hashable {
        case expected(String)
        case expectedOpenBrace(String)
        case expectedIdentifier
        case unexpectedRemainder
    }

    public var reason: Reason
    public var offset: String.Index
}

public indirect enum Expression<R>: Hashable where R: Hashable {
    case variable(name: String)
    case `if`(condition: R, body: [R])
    case member(lhs: R, rhs: String)
}

extension Expression {
    func map<B>(_ transform: (R) -> B) -> Expression<B> {
        switch self {
        case let .variable(name: name): return .variable(name: name)
        case let .if(condition, body):
            return .if(condition: transform(condition), body: body.map(transform))
        case let .member(lhs: lhs, rhs: rhs):
            return .member(lhs: transform(lhs), rhs: rhs)
        }
    }
}

public struct AnnotatedExpression: Hashable {
    public var expression: Expression<AnnotatedExpression>
    public var range: Range<String.Index>
}

public extension AnnotatedExpression {
    var simple: SimpleExpression {
        SimpleExpression(expression: expression.map { $0.simple })
    }
}

public struct SimpleExpression: Hashable, CustomStringConvertible {
    public init(expression: Expression<SimpleExpression>) {
        self.expression = expression
    }

    public var expression: Expression<SimpleExpression>

    public var description: String {
        "\(expression)"
    }
}

public extension String {
    func parseScript() throws -> AnnotatedExpression {
        var remainder = self[...]
        let result = try remainder.parseScript()
        guard remainder.isEmpty else {
            throw ScriptParseError(reason: ScriptParseError.Reason.unexpectedRemainder, offset: remainder.startIndex)
        }
        return result
    }
}

extension Substring {
    mutating func remove(prefix: String) -> Bool {
        guard hasPrefix(prefix) else { return false }
        removeFirst(prefix.count)
        return true
    }

    mutating func skipWS() {
        while first?.isWhitespace == true {
            removeFirst()
        }
    }

    func err(_ reason: ScriptParseError.Reason) -> ScriptParseError {
        ScriptParseError(reason: reason, offset: startIndex)
    }

    mutating func parseScript() throws -> AnnotatedExpression {
//        let expressionStart = startIndex
//        if remove(prefix: "{") {}
//
        throw err(.unexpectedRemainder)
    }
}
