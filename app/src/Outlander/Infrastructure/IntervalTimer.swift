//
//  IntervalTimer.swift
//  Outlander
//
//  Created by Joseph McBride on 5/17/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Foundation

struct IntervalValue {
    var name: String
    var value: Int
    var percent: Float
}

public class IntervalTimer {
    let context: GameContext
    let variable: String
    var timer: Timer?

    var interval: (IntervalValue) -> () = {val in}

    private var current = 0
    private var max = 0

    init(_ context: GameContext, variable: String) {
        self.context = context
        self.variable = variable
    }

    func set(value: Int) {
        self.current = value
        self.max = value
        
        self.run()

        let val = IntervalValue(name: self.variable, value: value, percent: 1.0)
        self.send(val)
    }

    private func send(_ value: IntervalValue) {
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

    @objc func fire(timer: Timer) {
        self.current -= 1
        
        var percent:Float = 0.0

        if self.current <= 0 {
            self.current = 0
            self.timer?.invalidate()
            self.timer = nil
        } else {

            percent = Float(self.current) / Float(self.max)
        }

        self.send(IntervalValue(name: self.variable, value: self.current, percent: percent))
    }
}
