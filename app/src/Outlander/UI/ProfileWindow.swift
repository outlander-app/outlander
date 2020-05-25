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
            print("selected profile", self.selected ?? "")
        }
    }

    @IBOutlet weak var tableView: NSTableView!
    
    override var windowNibName: String! {
        return "ProfileWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        self.profiles = self.context?.allProfiles() ?? []
    }

    @IBAction func ok(_ sender: Any) {
        self.window!.sheetParent!.endSheet(self.window!, returnCode: .OK)
    }

    @IBAction func cancel(_ sender: Any) {
        self.window!.sheetParent!.endSheet(self.window!, returnCode: .cancel)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.profiles.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < self.profiles.count else {
            return nil
        }

        return self.profiles[row]
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = self.tableView.selectedRow

        if(selectedRow > -1 && selectedRow < self.profiles.count) {
            self.selected = self.profiles[selectedRow]
        }
        else {
            self.selected = nil;
        }
    }
}
