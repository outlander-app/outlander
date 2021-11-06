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
    @IBOutlet var stunnedIcon: IndicatorView!
    @IBOutlet var bleedingIcon: IndicatorView!
    @IBOutlet var webbedIcon: IndicatorView!
    @IBOutlet var poisonedIcon: IndicatorView!

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

    var bleeding: Bool = false {
        didSet {
            setValues()
        }
    }

    var stunned: Bool = false {
        didSet {
            setValues()
        }
    }

    var poisoned: Bool = false {
        didSet {
            setValues()
        }
    }

    var webbed: Bool = false {
        didSet {
            setValues()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setValues()
    }

    func setIndicator(name: String, enabled: Bool) {
        DispatchQueue.main.async { [self] in
            switch name {
            case "bleeding":
                bleeding = enabled
            case "stunned":
                stunned = enabled
            case "poisoned":
                poisoned = enabled
            case "webbed":
                webbed = enabled
            default:
                print("** unknown indicator \(name):\(enabled) **")
            }
        }
    }

    func setValues() {
        if roundtime > 0 {
            roundtimeLabel.stringValue = "\(roundtime)"
        } else {
            roundtimeLabel.stringValue = ""
        }

        leftHandLabel.stringValue = "L: \(leftHand)"
        rightHandLabel.stringValue = "R: \(rightHand)"
        spellLabel.stringValue = "S: \(spell)"

        directionsView?.availableDirections = avaialbleDirections

        bleedingIcon?.toggle = bleeding
        poisonedIcon?.toggle = poisoned
        stunnedIcon?.toggle = stunned
        webbedIcon?.toggle = stunned
    }
}
