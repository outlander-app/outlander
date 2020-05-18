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

    var interval: (IntervalValue<T>) -> () = {val in}
    
    init(_ context: GameContext, variable: String) {
        self.context = context
        self.variable = variable
    }

    func set(_ value: T) {
        self.value = value

        self.run()
        
        let val = IntervalValue(name: self.variable, value: value, percent: 1.0)
        self.send(val)
    }

    func send(_ value: IntervalValue<T>) {
        self.context.globalVars[self.variable] = "\(value.value)"
        self.interval(value)
    }
    
    private func run() {
        guard timer == nil else {
            return
        }
        
        self.timer = Timer(timeInterval: 1.0, target: self, selector: #selector(fire(timer:)), userInfo: nil, repeats: true)
        self.timer?.tolerance = 0.2

        RunLoop.current.add(self.timer!, forMode: .common)
    }

    func stop() {
        self.timer?.invalidate()
        self.timer = nil
    }

    @objc func fire(timer: Timer) {
        self.onTick()
    }

    open func onTick() {
    }
}

public class RoundtimeTimer : BaseIntervalTimer<Int> {
    private var current = 0
    private var max = 0

    override func set(_ value: Int) {
        self.current = value
        self.max = value

        super.set(value)
    }

    override public func onTick() {
        self.current -= 1

        var percent:Float = 0.0

        if self.current <= 0 {
            self.current = 0
            self.stop()
        } else {

            percent = Float(self.current) / Float(self.max)
        }

        self.send(IntervalValue<Int>(name: self.variable, value: self.current, percent: percent))
    }
}

public class SpellTimer : BaseIntervalTimer<String> {
    var count = 0

    override func set(_ value: String) {
        guard self.value != value else {
            return
        }

        if value.count == 0 || value == "None" {
            self.count = 0
        }

        super.set(value)
    }

    override func send(_ value: IntervalValue<String>) {
        self.context.globalVars[self.variable] = "\(Int(value.percent))"
        self.interval(value)
    }

    override public func onTick() {
        self.count += 1

        if self.value == nil || (self.value ?? "").count == 0 || self.value == "None" {
            self.count = 0
            self.stop()
        }

        self.send(IntervalValue<String>(name: self.variable, value: self.value ?? "None", percent: Float(self.count)))
    }
}
