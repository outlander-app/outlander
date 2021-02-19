//
//  Combinators.swift
//  Outlander
//
//  Created by Joe McBride on 2/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

public struct Parser<A> {
    public typealias Stream = String.SubSequence
    let parse: (Stream) -> (A, Stream)?
}

public extension Parser {
    func run(_ x: String) -> (A, Stream)? {
        parse(x[...])
    }

    func res<Result>(_ res: Result) -> Parser<Result> {
        Parser<Result> { stream in
            guard let (_, newStream) = self.parse(stream) else { return nil }
            return (res, newStream)
        }
    }

    func map<Result>(_ f: @escaping (A) -> Result) -> Parser<Result> {
        Parser<Result> { stream in
            guard let (result, newStream) = self.parse(stream) else { return nil }
            return (f(result), newStream)
        }
    }

    func flatMap<Result>(_ f: @escaping (A) -> Parser<Result>) -> Parser<Result> {
        Parser<Result> { stream in
            guard let (result, newStream) = self.parse(stream) else { return nil }
            return f(result).parse(newStream)
        }
    }
}
