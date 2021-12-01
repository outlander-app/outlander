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

    @IBOutlet var tableView: NSTableView?

    override var windowNibName: String! {
        "ProfileWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        loadProfiles()
    }

    func loadProfiles() {
        profiles = context?.allProfiles() ?? []
        tableView?.reloadData()
    }

    @IBAction func ok(_: Any) {
        window!.sheetParent!.endSheet(window!, returnCode: .OK)
    }

    @IBAction func cancel(_: Any) {
        window!.sheetParent!.endSheet(window!, returnCode: .cancel)
    }

    func numberOfRows(in _: NSTableView) -> Int {
        profiles.count
    }

    func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
        guard row < profiles.count else {
            return nil
        }

        return profiles[row]
    }

    func tableViewSelectionDidChange(_: Notification) {
        guard let selectedRow = tableView?.selectedRow else {
            return
        }

        if selectedRow > -1, selectedRow < profiles.count {
            selected = profiles[selectedRow]
        } else {
            selected = nil
        }
    }
}
