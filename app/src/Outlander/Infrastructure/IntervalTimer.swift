//
//  IntervalTimer.swift
//  Outlander
//
//  Created by Joseph McBride on 5/17/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct IntervalValue<T> {
    var name: String
    var value: T
    var percent: Float
}

public class BaseIntervalTimer<T> {
    let context: GameContext
    let variable: String
    var timer: Timer?
    var value: T?

    var initialPercent: Float

    var interval: (IntervalValue<T>) -> Void = { _ in }

    init(_ context: GameContext, variable: String, initialPercent: Float = 1.0) {
        self.context = context
        self.variable = variable
        self.initialPercent = initialPercent
    }

    func set(_ value: T) {
        self.value = value

        run()

        let val = IntervalValue(name: variable, value: value, percent: initialPercent)
        send(val)
    }

    func send(_ value: IntervalValue<T>) {
        context.globalVars[variable] = "\(value.value)"
        interval(value)
    }

    private func run() {
        guard timer == nil else {
            return
        }

        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(fire(timer:)), userInfo: nil, repeats: true)
        timer?.tolerance = 0.2

        RunLoop.current.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    @objc func fire(timer _: Timer) {
        onTick()
    }

    open func onTick() {}
}

public class RoundtimeTimer: BaseIntervalTimer<Int> {
    private var current = 0
    private var max = 0

    override func set(_ value: Int) {
        current = value
        max = value

        super.set(value)
    }

    override public func onTick() {
        current -= 1

        var percent: Float = 0.0

        if current <= 0 {
            current = 0
            stop()
        } else {
            percent = Float(current) / Float(max)
        }

        send(IntervalValue<Int>(name: variable, value: current, percent: percent))
    }
}

public class SpellTimer: BaseIntervalTimer<String> {
    var count = 0

    override func set(_ value: String) {
        guard self.value != value else {
            return
        }

        if value.count == 0 || value == "None" {
            count = 0
        }

        super.set(value)
    }

    override func send(_ value: IntervalValue<String>) {
        context.globalVars[variable] = "\(Int(value.percent))"
        interval(value)
    }

    override public func onTick() {
        count += 1

        if value == nil || (value ?? "").count == 0 || value == "None" {
            count = 0
            stop()
        }

        send(IntervalValue<String>(name: variable, value: value ?? "None", percent: Float(count)))
    }
}
