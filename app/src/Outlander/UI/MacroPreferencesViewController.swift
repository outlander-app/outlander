//
//  MacroPreferencesViewController.swift
//  Outlander
//
//  Created by Codex on 5/18/25.
//

import Cocoa

final class MacroPreferencesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    private let category: MacroPreferencesCategory
    private var store: MacroPreferencesStore?
    private var context: GameContext?
    private var currentGroup: MacroModifierGroup

    // MARK: - UI

    private let segmentedControl: NSSegmentedControl
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let footerLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.isHidden = true
        return label
    }()
    private let infoLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Open a game window to edit macros.")
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = NSColor.secondaryLabelColor
        label.alignment = .center
        label.isHidden = true
        return label
    }()
    private var macroSetPopup: NSPopUpButton?
    private lazy var okButton: NSButton = {
        let button = NSButton(title: "OK", target: self, action: #selector(saveAndClose))
        button.keyEquivalent = "\r"
        return button
    }()
    private lazy var cancelButton: NSButton = {
        let button = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        button.keyEquivalent = "\u{1b}"
        return button
    }()

    private let keyColumnIdentifier = NSUserInterfaceItemIdentifier("key")
    private let macroColumnIdentifier = NSUserInterfaceItemIdentifier("macro")

    init(category: MacroPreferencesCategory) {
        self.category = category
        let modifierGroups = MacroModifierGroup.groups(for: category)
        let labels = modifierGroups.map(\.title)
        self.currentGroup = modifierGroups.first ?? .command
        self.segmentedControl = NSSegmentedControl(labels: labels, trackingMode: .selectOne, target: nil, action: nil)
        super.init(nibName: nil, bundle: nil)
        self.segmentedControl.target = self
        self.segmentedControl.action = #selector(modifierChanged(_:))
        self.segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        self.segmentedControl.segmentStyle = .automatic
        self.segmentedControl.selectedSegment = labels.isEmpty ? -1 : 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 420))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if let cell = okButton.cell as? NSButtonCell {
            view.window?.defaultButtonCell = cell
        }
    }

    func updateContext(_ context: GameContext) {
        self.context = context
        self.store = MacroPreferencesStore(category: category, context: context)
        self.infoLabel.isHidden = true
        reloadData()
    }

    // MARK: - Table Data

    private var keyDefinitions: [MacroKeyDefinition] {
        store?.keyDefinitions ?? []
    }

    private var modifierGroups: [MacroModifierGroup] {
        store?.modifierGroups ?? MacroModifierGroup.groups(for: category)
    }

    private func reloadData() {
        guard let store else {
            segmentedControl.isEnabled = false
            infoLabel.isHidden = false
            tableView.reloadData()
            return
        }

        segmentedControl.isEnabled = !store.modifierGroups.isEmpty
        if segmentedControl.selectedSegment < 0, !store.modifierGroups.isEmpty {
            segmentedControl.selectedSegment = 0
            currentGroup = store.modifierGroups[0]
        } else if segmentedControl.selectedSegment < store.modifierGroups.count {
            currentGroup = store.modifierGroups[segmentedControl.selectedSegment]
        }

        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func modifierChanged(_ sender: NSSegmentedControl) {
        guard sender.selectedSegment >= 0 else { return }
        let groups = modifierGroups
        guard sender.selectedSegment < groups.count else { return }
        currentGroup = groups[sender.selectedSegment]
        tableView.reloadData()
    }

    @objc private func saveAndClose() {
        guard let context, var store else {
            view.window?.close()
            return
        }

        for group in store.modifierGroups {
            let flags = group.flags
            for definition in store.keyDefinitions {
                if store.isReserved(group: group, key: definition.key) {
                    continue
                }
                let rawValue = store.value(for: group, key: definition.key)
                let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
                context.setMacro(action: trimmed.isEmpty ? nil : trimmed, for: definition.key, modifiers: flags)
            }
        }

        let files = LocalFileSystem(context.applicationSettings)
        MacroLoader(files).save(context.applicationSettings, macros: context.macros)
        context.events2.echoText("Macros saved")

        view.window?.close()
    }

    @objc private func cancel() {
        view.window?.close()
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in _: NSTableView) -> Int {
        keyDefinitions.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < keyDefinitions.count else {
            return nil
        }

        let definition = keyDefinitions[row]

        if tableColumn?.identifier == keyColumnIdentifier {
            let view = tableView.makeView(withIdentifier: keyColumnIdentifier, owner: self) as? NSTableCellView ?? {
                let cell = NSTableCellView()
                let textField = NSTextField(labelWithString: "")
                textField.translatesAutoresizingMaskIntoConstraints = false
                cell.addSubview(textField)
                cell.textField = textField

                NSLayoutConstraint.activate([
                    textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                    textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                    textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                ])

                cell.identifier = keyColumnIdentifier
                return cell
            }()

            view.textField?.stringValue = definition.title
            return view
        }

        let cell = tableView.makeView(withIdentifier: macroColumnIdentifier, owner: self) as? NSTableCellView ?? {
            let cell = NSTableCellView()
            let textField = NSTextField()
            textField.translatesAutoresizingMaskIntoConstraints = false
            textField.isEditable = true
            textField.isBordered = false
            textField.drawsBackground = false
            textField.lineBreakMode = .byTruncatingTail
            textField.delegate = self
            cell.addSubview(textField)
            cell.textField = textField
            cell.identifier = macroColumnIdentifier

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            ])

            return cell
        }()

        if let store, store.isReserved(group: currentGroup, key: definition.key) {
            cell.textField?.stringValue = store.reservedLabel(group: currentGroup, key: definition.key) ?? "Reserved"
            cell.textField?.isEditable = false
            cell.textField?.textColor = NSColor.secondaryLabelColor
        } else if let store {
            cell.textField?.isEditable = true
            cell.textField?.isEnabled = true
            cell.textField?.textColor = NSColor.labelColor
            cell.textField?.stringValue = store.value(for: currentGroup, key: definition.key)
        } else {
            cell.textField?.stringValue = ""
            cell.textField?.isEditable = false
            cell.textField?.isEnabled = false
        }

        cell.textField?.tag = row
        return cell
    }

    func tableView(_: NSTableView, shouldEdit _: NSTableColumn?, row: Int) -> Bool {
        guard row < keyDefinitions.count else { return false }
        guard let store else { return false }
        return !store.isReserved(group: currentGroup, key: keyDefinitions[row].key)
    }

    // MARK: - NSTextFieldDelegate

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        let row = textField.tag
        guard row >= 0, row < keyDefinitions.count else { return }
        guard var store else { return }
        let definition = keyDefinitions[row]
        guard !store.isReserved(group: currentGroup, key: definition.key) else { return }

        store.setValue(textField.stringValue, for: currentGroup, key: definition.key)
        self.store = store
        tableView.reloadData(forRowIndexes: IndexSet(integer: row), columnIndexes: IndexSet(integersIn: 0 ..< tableView.numberOfColumns))
    }

    // MARK: - Layout

    private func setupUI() {
        let modifierGroups = MacroModifierGroup.groups(for: category)
        segmentedControl.isEnabled = !modifierGroups.isEmpty

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.rowHeight = 24
        tableView.allowsColumnReordering = false
        tableView.allowsColumnResizing = false

        let keyColumn = NSTableColumn(identifier: keyColumnIdentifier)
        keyColumn.title = "Key"
        keyColumn.width = 100
        tableView.addTableColumn(keyColumn)

        let macroColumn = NSTableColumn(identifier: macroColumnIdentifier)
        macroColumn.title = "Macro"
        macroColumn.width = 360
        tableView.addTableColumn(macroColumn)

        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        okButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        let buttonStack = NSStackView(views: [cancelButton, okButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8

        view.addSubview(segmentedControl)
        view.addSubview(scrollView)
        view.addSubview(footerLabel)
        view.addSubview(buttonStack)
        view.addSubview(infoLabel)

        if category == .function {
            let popup = NSPopUpButton()
            popup.translatesAutoresizingMaskIntoConstraints = false
            popup.addItem(withTitle: "Macro Set 1")
            popup.isEnabled = false
            macroSetPopup = popup
            view.addSubview(popup)

            NSLayoutConstraint.activate([
                popup.centerYAnchor.constraint(equalTo: buttonStack.centerYAnchor),
                popup.trailingAnchor.constraint(equalTo: buttonStack.leadingAnchor, constant: -12),
            ])
        }

        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            infoLabel.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            infoLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),

            footerLabel.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            footerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            footerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: footerLabel.bottomAnchor, constant: 12),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
        ])

        reloadData()
    }
}
