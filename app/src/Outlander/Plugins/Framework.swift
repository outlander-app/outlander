//
//  Framework.swift
//  Outlander
//
//  Created by Joe McBride on 12/4/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

public protocol IHost {
    func send(text: String)
    func get(variable: String) -> String
    func set(variable: String, value: String)
    func get(preset: String) -> String?
}

public protocol OPlugin {
    var name: String { get }
    func initialize(host: IHost)
    func variableChanged(variable: String, value: String)
    func parse(input: String) -> String
    func parse(xml: String) -> String
    func parse(text: String) -> String
}
