//
//  AddProfileWindow.swift
//  Outlander
//
//  Created by Joe McBride on 1/14/22.
//  Copyright © 2022 Joe McBride. All rights reserved.
//

import Cocoa

enum WindowResult {
    case ok
    case cancel
}

class AddProfileWindow: NSWindowController {
    @IBOutlet var profileName: NSTextField!

    var completion: (WindowResult, String) -> Void = { _, _ in }
    var isValid: (String) -> Bool = { _ in false }

    override var windowNibName: String! {
        "AddProfileWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }

    @IBAction func ok(_: Any) {
        guard profileName.stringValue.count > 0, isValid(profileName.stringValue) else {
            return
        }

        completion(.ok, profileName.stringValue)
    }

    @IBAction func cancel(_: Any) {
        completion(.cancel, "")
    }
}
