//
//  Stack.swift
//  Outlander
//
//  Created by Joseph McBride on 7/29/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

public class Stack<T> {
    private var stack: [T] = []

    public func push(_ item: T) {
        stack.append(item)
    }

    public func pop() -> T {
        stack.remove(at: stack.count - 1)
    }

    public func peek() -> T? {
        stack.last
    }

    public func hasItems() -> Bool {
        stack.count > 0
    }

    public func count() -> Int {
        stack.count
    }

    public func clear() {
        stack.removeAll(keepingCapacity: true)
    }
}

enum RegexFactory {
    static let get: (String) -> (Regex?) = memoize { (pattern: String) in try? Regex(pattern, options: [.caseInsensitive]) }
}

func memoize<T: Hashable, U>(work: @escaping (T) -> U) -> (T) -> U {
    var memo = [T: U]()

    return { x in
        if let q = memo[x] {
            return q
        }
        let r = work(x)
        memo[x] = r
        return r
    }
}
