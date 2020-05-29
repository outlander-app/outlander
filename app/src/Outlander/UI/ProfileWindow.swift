//
//  ProfileWindow.swift
//  Outlander
//
//  Created by Joseph McBride on 5/22/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Cocoa

class ProfileWindow: NSWindowController, NSTableViewDelegate, NSTableViewDataSource {
    var profiles: [String] = []
    var context: GameContext?
    var selected: String? {
        didSet {
            print("selected profile", selected ?? "")
        }
    }

    @IBOutlet var tableView: NSTableView!

    override var windowNibName: String! {
        return "ProfileWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        profiles = context?.allProfiles() ?? []
    }

    @IBAction func ok(_: Any) {
        window!.sheetParent!.endSheet(window!, returnCode: .OK)
    }

    @IBAction func cancel(_: Any) {
        window!.sheetParent!.endSheet(window!, returnCode: .cancel)
    }

    func numberOfRows(in _: NSTableView) -> Int {
        return profiles.count
    }

    func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
        guard row < profiles.count else {
            return nil
        }

        return profiles[row]
    }

    func tableViewSelectionDidChange(_: Notification) {
        let selectedRow = tableView.selectedRow

        if selectedRow > -1, selectedRow < profiles.count {
            selected = profiles[selectedRow]
        } else {
            selected = nil
        }
    }
}
