//
//  ProfileWindow.swift
//  Outlander
//
//  Created by Joseph McBride on 5/22/20.
//  Copyright © 2020 Joe McBride. All rights reserved.
//

import Cocoa

class ProfileWindow: NSWindowController, NSTableViewDelegate, NSTableViewDataSource {
    private var addWindow: AddProfileWindow?
    var profiles: [String] = []
    var context: GameContext?
    var selected: String? {
        guard let selectedRow = tableView?.selectedRow else {
            return nil
        }

        if selectedRow > -1, selectedRow < profiles.count {
            return profiles[selectedRow]
        }

        return nil
    }

    @IBOutlet var tableView: NSTableView?

    override var windowNibName: String! {
        "ProfileWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        loadProfiles()
    }

    @IBAction func addRemoveProfile(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            addWindow = AddProfileWindow()
            addWindow?.isValid = { profileName in
                !self.profiles.contains(profileName)
            }
            addWindow?.completion = { res, profileName in
                guard res == .ok else {
                    self.addWindow?.window?.close()
                    NSApplication.shared.stopModal()
                    return
                }
                self.addWindow?.window?.close()
                NSApplication.shared.stopModal()
                let settings = self.context!.applicationSettings
                let profileUrl = settings.paths.profiles.appendingPathComponent(profileName)
                try? LocalFileSystem(settings).ensure(folder: profileUrl)
                self.loadProfiles()
                var foundIdx = -1
                for (idx, p) in self.profiles.enumerated() {
                    if p == profileName {
                        foundIdx = idx
                        break
                    }
                }
                let index = IndexSet(integer: foundIdx)
                self.tableView?.selectRowIndexes(index, byExtendingSelection: false)
            }
            NSApplication.shared.runModal(for: addWindow!.window!)
        case 1:
            if let selected = selected, !selected.isEmpty {
                let alert = NSAlert()
                alert.messageText = "Are you sure you want to delete profile '\(selected)'?\n\nThis will delete all variables, highlights, triggers, etc. for this profile."
                alert.addButton(withTitle: "Yes")
                alert.addButton(withTitle: "No")
                alert.alertStyle = .warning
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    let profileUrl = context!.applicationSettings.paths.profiles.appendingPathComponent(selected)
                    try? LocalFileSystem(context!.applicationSettings).remove(folder: profileUrl)
                    loadProfiles()
                }
            }
        default:
            break
        }
    }

    func loadProfiles() {
        profiles = context?.allProfiles() ?? []
        tableView?.reloadData()
        let index = IndexSet(integer: 0)
        tableView?.selectRowIndexes(index, byExtendingSelection: false)
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
}
