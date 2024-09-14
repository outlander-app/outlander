//
//  BoolExtensions.swift
//  Outlander
//
//  Created by Joe McBride on 10/16/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

extension Bool {
    func toYesNoString() -> String {
        self ? "yes" : "no"
    }

    func toZeroOneString() -> String {
        self ? "1" : "0"
    }
}
