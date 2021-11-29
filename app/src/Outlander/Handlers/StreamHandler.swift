//
//  StreamHandler.swift
//  Outlander
//
//  Created by Joe McBride on 11/5/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation

protocol StreamHandler {
    func stream(_ data: String, with context: GameContext)
}
