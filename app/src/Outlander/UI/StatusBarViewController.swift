//
//  StatusBarViewController.swift
//  Outlander
//
//  Created by Joe McBride on 10/26/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

import Cocoa

class StatusBarViewController: NSViewController {
    @IBOutlet var roundtimeLabel: NSTextField!
    @IBOutlet var leftHandLabel: NSTextField!
    @IBOutlet var rightHandLabel: NSTextField!
    @IBOutlet var spellLabel: NSTextField!
    @IBOutlet var directionsView: DirectionsView?
    @IBOutlet var standingIcon: StandingIndicatorView!
    @IBOutlet var stunnedIcon: IndicatorView!
    @IBOutlet var bleedingIcon: IndicatorView!
    @IBOutlet var invisibleIcon: IndicatorView!
    @IBOutlet var hiddenIcon: IndicatorView!
    @IBOutlet var joinedIcon: IndicatorView!
    @IBOutlet var webbedIcon: IndicatorView!
    @IBOutlet var poisonedIcon: IndicatorView!

    @IBInspectable
    public var rtTextColor = NSColor(hex: "#f5f5f5")! {
        didSet {
            setValues()
        }
    }

    @IBInspectable
    public var textColor = NSColor(hex: "#f5f5f5")! {
        didSet {
            setValues()
        }
    }

    var roundtime: Int = 0 {
        didSet {
            setValues()
        }
    }

    var leftHand: String = "Empty" {
        didSet {
            setValues()
        }
    }

    var rightHand: String = "Empty" {
        didSet {
            setValues()
        }
    }

    var spell: String = "None" {
        didSet {
            setValues()
        }
    }

    var avaialbleDirections: [String] = [] {
        didSet {
            setValues()
        }
    }

    var indicators: [String: Bool] = [
        "dead": false,
        "standing": false,
        "kneeling": false,
        "sitting": false,
        "prone": false,
        "stunned": false,
        "bleeding": false,
        "invisible": false,
        "hidden": false,
        "joined": false,
        "webbed": false,
        "poisoned": false,
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func loadImages(context: GameContext) {
        let files = LocalFileSystem(context.applicationSettings)
        let images = IconLoader(files).load(context.applicationSettings.paths)

        standingIcon.images = mapImages(files, images, targets: [
            "dead",
            "standing",
            "sitting",
            "kneeling",
            "prone",
        ])

        bleedingIcon.images = mapImages(files, images, targets: [
            "bleeding",
        ])

        stunnedIcon.images = mapImages(files, images, targets: [
            "stunned",
        ])

        invisibleIcon.images = mapImages(files, images, targets: [
            "invisible",
        ])

        hiddenIcon.images = mapImages(files, images, targets: [
            "hidden",
        ])

        joinedIcon.images = mapImages(files, images, targets: [
            "joined",
        ])

        webbedIcon.images = mapImages(files, images, targets: [
            "webbed",
        ])

        poisonedIcon.images = mapImages(files, images, targets: [
            "poisoned",
        ])

        directionsView?.images = mapImages(files, images, targets: [
            "directions",
            "north",
            "south",
            "east",
            "west",
            "northeast",
            "northwest",
            "southeast",
            "southwest",
            "out",
            "up",
            "down",
        ])

        setValues()
    }

    func mapImages(_ files: FileSystem, _ images: [String: URL], targets: [String]) -> [String: NSImage] {
        var res: [String: NSImage] = [:]
        files.access {
            res = Dictionary(targets.map { ($0, NSImage(contentsOf: images[$0]!)!) }) { name, _ in name }
        }
        return res
    }

    func setIndicator(name: String, enabled: Bool) {
        DispatchQueue.main.async { [self] in
            print("Setting \(name) to \(enabled)")
            self.indicators[name] = enabled
            self.setValues()
        }
    }

    func setValues() {
        roundtimeLabel.textColor = rtTextColor
        leftHandLabel.textColor = textColor
        rightHandLabel.textColor = textColor
        spellLabel.textColor = textColor

        if roundtime > 0 {
            roundtimeLabel.stringValue = "\(roundtime)"
        } else {
            roundtimeLabel.stringValue = ""
        }

        leftHandLabel.stringValue = "L: \(leftHand)"
        rightHandLabel.stringValue = "R: \(rightHand)"
        spellLabel.stringValue = "S: \(spell)"

        directionsView?.availableDirections = avaialbleDirections

        stunnedIcon?.toggle = indicators["stunned"] ?? false
        bleedingIcon?.toggle = indicators["bleeding"] ?? false
        invisibleIcon?.toggle = indicators["invisible"] ?? false
        hiddenIcon?.toggle = indicators["hidden"] ?? false
        joinedIcon?.toggle = indicators["joined"] ?? false
        webbedIcon?.toggle = indicators["webbed"] ?? false
        poisonedIcon?.toggle = indicators["poisoned"] ?? false

        standingIcon?.isPlayerDead = indicators["dead"] ?? false

        if indicators["standing"] == true {
            standingIcon?.imageName = "standing"
        } else if indicators["kneeling"] == true {
            standingIcon?.imageName = "kneeling"
        } else if indicators["sitting"] == true {
            standingIcon?.imageName = "sitting"
        } else if indicators["prone"] == true {
            standingIcon?.imageName = "prone"
        }
    }
}
