//
//  ViewController.swift
//  Outlander
//
//  Created by Joseph McBride on 7/18/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa

class MyViewController: NSViewController {

    var _authServer: AuthenticationServer?
    var _gameServer: GameServer?
    @IBOutlet weak var textField1: NSTextField!
    @IBOutlet weak var button: NSButton!
    var textFieldDelegate: TextFieldDelegate?
    var targetAction: TargetAction?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.textFieldDelegate = textField1.onTextChanged { text in
            print("changed: \(text)")
        }

        self.targetAction = self.button.onClick {
            print("button clicked")
            self._gameServer?.sendCommand(command: "look")
        }

//        _authServer = AuthenticationServer()
//        _gameServer = GameServer({ state in
//            print("game state: \(state)")
//        })
//
//        _authServer?.authenticate(
//            AuthInfo(
//                host: "eaccess.play.net",
//                port: 7900,
//                account: "",
//                password: "",
//                game: "DR",
//                character: ""),
//            callback: { [weak self] result in
//
//                switch result {
//                case .success(let connection):
//                    self?._gameServer?.connect(host: connection.host, port: connection.port, key: connection.key)
//
//                default:
//                    print("auth result: \(result)")
//                }
//            }
//        )
    }

    override var representedObject: Any? {
        didSet {
        }
    }
}
