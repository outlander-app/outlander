//
//  LoginWindow.swift
//  Outlander
//
//  Created by Joseph McBride on 5/22/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Cocoa

class LoginWindow: NSWindowController, NSComboBoxDelegate, NSWindowDelegate {
    @IBOutlet var accountTextField: NSTextField?
    @IBOutlet var passwordTextField: NSSecureTextField?
    @IBOutlet var characterTextField: NSTextField?
    @IBOutlet var gameComboBox: NSComboBox?

    override var windowNibName: String! {
        return "LoginWindow"
    }

    var account: String = ""
    var password: String = ""
    var game: String = ""
    var character: String = ""

    override func windowDidLoad() {
        super.windowDidLoad()

        gameComboBox?.removeAllItems()
        gameComboBox?.addItems(withObjectValues: ["DR", "DRX", "DRF", "DRT"])

        accountTextField?.stringValue = account
        passwordTextField?.stringValue = password
        gameComboBox?.stringValue = game
        characterTextField?.stringValue = character
    }

    @IBAction func connect(_: Any) {
        setValues()
        window!.sheetParent!.endSheet(window!, returnCode: .OK)
    }

    @IBAction func cancel(_: Any) {
        setValues()
        window!.sheetParent!.endSheet(window!, returnCode: .cancel)
    }

    func controlTextDidEndEditing(_: Notification) {
        game = gameComboBox?.stringValue ?? "DR"
    }

    private func setValues() {
        account = accountTextField?.stringValue ?? ""
        password = passwordTextField?.stringValue ?? ""
        game = gameComboBox?.stringValue ?? ""
        character = characterTextField?.stringValue ?? ""

        passwordTextField?.stringValue = ""
    }
}
