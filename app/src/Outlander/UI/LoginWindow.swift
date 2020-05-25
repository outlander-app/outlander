//
//  LoginWindow.swift
//  Outlander
//
//  Created by Joseph McBride on 5/22/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Cocoa

class LoginWindow: NSWindowController, NSComboBoxDelegate, NSWindowDelegate {
    @IBOutlet weak var accountTextField: NSTextField?
    @IBOutlet weak var passwordTextField: NSSecureTextField?
    @IBOutlet weak var characterTextField: NSTextField?
    @IBOutlet weak var gameComboBox: NSComboBox?

    override var windowNibName: String! {
        return "LoginWindow"
    }

    var account: String = ""
    var password: String = ""
    var game: String = ""
    var character: String = ""

    override func windowDidLoad() {
        super.windowDidLoad()

        self.gameComboBox?.removeAllItems()
        self.gameComboBox?.addItems(withObjectValues: ["DR", "DRX", "DRF", "DRT"])
       
        self.accountTextField?.stringValue = self.account
        self.passwordTextField?.stringValue = self.password
        self.gameComboBox?.stringValue = self.game
        self.characterTextField?.stringValue = self.character
    }

    @IBAction func connect(_ sender: Any) {
        self.setValues()
        self.window!.sheetParent!.endSheet(self.window!, returnCode: .OK)
    }

    @IBAction func cancel(_ sender: Any) {
        self.setValues()
        self.window!.sheetParent!.endSheet(self.window!, returnCode: .cancel)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        self.game = self.gameComboBox?.stringValue ?? "DR"
    }

    private func setValues() {
        self.account = self.accountTextField?.stringValue ?? ""
        self.password = self.passwordTextField?.stringValue ?? ""
        self.game = self.gameComboBox?.stringValue ?? ""
        self.character = self.characterTextField?.stringValue ?? ""
        
        self.passwordTextField?.stringValue = ""
    }
}
