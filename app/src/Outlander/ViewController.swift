//
//  ViewController.swift
//  Outlander
//
//  Created by Joseph McBride on 7/18/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var _authServer: AuthenticationServer?
    var _gameServer: GameServer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _authServer = AuthenticationServer()
        _gameServer = GameServer({ state in
            print("game state: \(state)")
        })
        
        _authServer?.authenticate(
            AuthInfo(
                host: "eaccess.play.net",
                port: 7900,
                account: "",
                password: "",
                game: "DR",
                character: ""),
            callback: { result in

                switch result {
                case .success(let connection):
                    self._gameServer?.connect(host: connection.host, port: connection.port, key: connection.key)

                default:
                    print("auth result: \(result)")
                }
            }
        )
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    @IBAction func click(_ sender: Any) {
        _gameServer?.sendCommand(command: "look")
    }
}
