//
//  WindowSettingsViewController.swift
//  Outlander
//
//  Created by Joe McBride on 12/10/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

struct WindowViewSettings {
    var x: Double
    var y: Double
    var height: Double
    var width: Double
    var padding: String
}

class WindowSettingsViewController: NSViewController, NSTextFieldDelegate {
    @IBOutlet var xField: NSTextField!
    @IBOutlet var yField: NSTextField!
    @IBOutlet var hField: NSTextField!
    @IBOutlet var wField: NSTextField!
    @IBOutlet var paddingField: NSTextField!

    typealias SettingsChanged = ((WindowViewSettings) -> Void)

    private var loaded = false

    var settings = WindowViewSettings(x: 0, y: 0, height: 0, width: 0, padding: "0") {
        didSet {
            setValues()
        }
    }

    var onSettingsChanged: SettingsChanged = { _ in }

    override func viewDidLoad() {
        super.viewDidLoad()
        loaded = true
        setValues()

        xField.delegate = self
        yField.delegate = self
        hField.delegate = self
        wField.delegate = self
        paddingField.delegate = self
    }

    func setValues() {
        guard loaded else { return }

        xField.stringValue = settings.x.formattedNumber
        yField.stringValue = settings.y.formattedNumber
        hField.stringValue = settings.height.formattedNumber
        wField.stringValue = settings.width.formattedNumber
        paddingField.stringValue = settings.padding
    }

    func controlTextDidEndEditing(_: Notification) {
        guard let x = Double(xField.stringValue), let y = Double(yField.stringValue), let width = Double(wField.stringValue), let height = Double(hField.stringValue) else {
            return
        }

        onSettingsChanged(WindowViewSettings(x: x, y: y, height: height, width: width, padding: paddingField.stringValue))
    }
}
