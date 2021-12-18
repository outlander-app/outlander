//
//  AtomicQueue.swift
//  Outlander
//
//  Created by Joe McBride on 12/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

class AtomicQueue {
    var label: String
    var queue: DispatchQueue
    let key = DispatchSpecificKey<Void>()

    var enabled = true

    var isOnQueue: Bool {
        DispatchQueue.getSpecific(key: key) != nil
    }

    init(label: String, qos: DispatchQoS = .unspecified, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency = .inherit) {
        self.label = label
        queue = DispatchQueue(label: label, qos: qos, autoreleaseFrequency: autoreleaseFrequency)
        queue.setSpecific(key: key, value: ())
    }

    deinit {
        self.queue.setSpecific(key: key, value: nil)
    }

    func async(execute work: @escaping @convention(block) () -> Void) {
        print("is on target queue: \(isOnQueue)")
        guard isOnQueue == false, enabled == true else {
            work()
            return
        }

        queue.async {
            work()
        }
    }

    func sync(execute work: @escaping @convention(block) () -> Void) {
        guard isOnQueue == false, enabled == true else {
            work()
            return
        }

        queue.sync {
            work()
        }
    }
}
