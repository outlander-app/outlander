//
//  LoginWindow.swift
//  Outlander
//
//  Created by Joseph McBride on 5/22/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Cocoa

class LoginWindow: NSWindowController {

    override var windowNibName: String! {
        return "LoginWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
    }

    @IBAction func connect(_ sender: Any) {
        self.window!.sheetParent!.endSheet(self.window!, returnCode: .OK)
    }

    @IBAction func cancel(_ sender: Any) {
        self.window!.sheetParent!.endSheet(self.window!, returnCode: .cancel)
    }
}
