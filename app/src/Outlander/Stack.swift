//
//  Stack.swift
//  Outlander
//
//  Created by Joseph McBride on 7/29/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

public class Stack<T>
{
    private var stack:[T] = []

    public func push(_ item: T) {
        stack.append(item)
    }

    public func pop() -> T {
        return stack.removeLast()
    }

    public func peek() -> T? {
        return stack.last
    }

    public func hasItems() -> Bool {
        return stack.count > 0
    }
    
    public func count() -> Int {
        return stack.count
    }

    public func clear() {
        stack.removeAll(keepingCapacity: true)
    }
}
