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

    override func viewDidLoad() {
        super.viewDidLoad()

        setValues()
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
    }
}
