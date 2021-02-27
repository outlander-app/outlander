//
//  Keychain.swift
//  Outlander
//
//  Created by Joe McBride on 2/26/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Foundation
import KeychainSwift

class Keychain {
    let keychain = KeychainSwift()

    func get(passwordFor account: String) -> String? {
        return keychain.get(makeAccountKey(account))
    }

    func set(password: String, for account: String) {
        keychain.set(password, forKey: makeAccountKey(account), withAccess: .accessibleWhenUnlocked)
    }
    
    private func makeAccountKey(_ account: String) -> String {
        return "com.Outlander.account.\(account)"
    }
}
