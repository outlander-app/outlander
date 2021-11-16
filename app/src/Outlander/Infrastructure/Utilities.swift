//
//  Stack.swift
//  Outlander
//
//  Created by Joseph McBride on 7/29/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

public class Stack<T> {
    private var stack: [T] = []
    private var maxCapacity = 0

    init(_ maxCapacity: Int = 0) {
        self.maxCapacity = maxCapacity
    }

    public func push(_ item: T) {
        stack.append(item)

        if maxCapacity > 0, stack.count > maxCapacity {
            stack.removeFirst()
        }
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

    public var count: Int {
        stack.count
    }

    var last: T? {
        stack.last
    }

    var last2: T? {
        if stack.count < 2 {
            return nil
        }

        return stack[stack.count - 2]
    }

    public func clear() {
        stack.removeAll(keepingCapacity: true)
    }
}

class MemoizeHash<T: Hashable, U> {
    let lockQueue = DispatchQueue(label: "com.outlanderapp.memoize.\(UUID().uuidString)")
    var memo = [T: U]()
    var build: (T) -> U?

    init(_ build: @escaping (T) -> U?) {
        self.build = build
    }

    subscript(key: T) -> U? {
        lockQueue.sync(flags: .barrier) {
            if let res = memo[key] {
                return res
            }

            let r = self.build(key)
            memo[key] = r
            return r
        }
    }
}

enum RegexFactory {
    static let created = MemoizeHash<String, Regex>({ pattern in try? Regex(pattern, options: [.caseInsensitive, .anchorsMatchLines]) })
    static let get: (String) -> (Regex?) = { (pattern: String) in
        created[pattern]
    }
}

// not thread safe
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
