//
//  Stack.swift
//  Outlander
//
//  Created by Joseph McBride on 7/29/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

public class Queue<T> {
    private var lock: NSLock = NSLock()
    private var queue: [T] = []

    public func queue(_ item: T) {
        lock.lock()
        defer { lock.unlock() }
        queue.append(item)
    }

    public func dequeue() -> T? {
        lock.lock()
        defer { lock.unlock() }
        guard queue.count > 0 else {
            return nil
        }
        return queue.remove(at: 0)
    }

    public func peek() -> T? {
        lock.lock()
        defer { lock.unlock() }
        return queue.first
    }

    public func hasItems() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return queue.count > 0
    }

    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return queue.count
    }

    public var all: [T] {
        lock.lock()
        defer { lock.unlock() }
        return queue
    }
}

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

    @discardableResult public func pop() -> T? {
        guard stack.count > 0 else {
            return nil
        }
        return stack.remove(at: stack.count - 1)
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

    public var all: [T] {
        stack
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

    public func copy() -> Stack<T> {
        let copy = Stack<T>()
        for item in stack {
            copy.push(item)
        }
        return copy
    }
}

class MemoizeHash<T: Hashable, U> {
    private let lock = NSLock()
    var memo = [T: U]()
    var build: (T) -> U?

    init(_ build: @escaping (T) -> U?) {
        self.build = build
    }

    subscript(key: T) -> U? {
        lock.lock()
        defer { lock.unlock() }
        if let res = memo[key] {
            return res
        }

        let r = build(key)
        memo[key] = r
        return r
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

class DelayedTask {
    private let lock = NSLock()
    private var value: DispatchWorkItem?

    func reset() {
        lock.lock()
        value?.cancel()
        value = nil
        lock.unlock()
    }

    func set(_ duration: Double, queue: DispatchQueue = DispatchQueue.global(qos: .userInteractive), _ closure: @escaping () -> Void) {
        lock.lock()
        value = delay(duration, queue: queue, closure)
        lock.unlock()
    }
}

class AtomicArray<Element> {
    private let lock = NSLock()
    private var list: [Element] = []

    func append(_ item: Element) {
        lock.lock()
        list.append(item)
        lock.unlock()
    }

    func removeAll() {
        lock.lock()
        list.removeAll()
        lock.unlock()
    }
}

extension AtomicArray: Sequence {
    typealias Iterator = IndexingIterator<[Element]>

    func makeIterator() -> IndexingIterator<[Element]> {
        lock.lock()
        defer { lock.unlock() }
        return list.makeIterator()
    }
}

extension AtomicArray: Collection {
    typealias Index = Int

    var startIndex: Index {
        lock.lock()
        defer { lock.unlock() }
        return list.startIndex
    }

    var endIndex: Index {
        lock.lock()
        defer { lock.unlock() }
        return list.endIndex
    }

    subscript (position: Index) -> Iterator.Element {
        lock.lock()
        defer { lock.unlock() }
        precondition(position > -1 && position < list.count, "out of bounds")
        return list[position]
    }
    
    func index(after i: Index) -> Index {
        lock.lock()
        defer { lock.unlock() }
        return list.index(after: i)
    }

    func remove(at index: Index) {
        lock.lock()
        defer { lock.unlock() }
        list.remove(at: index)
    }
}
