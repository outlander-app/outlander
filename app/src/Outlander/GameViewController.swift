//
//  GameViewController.swift
//  Outlander
//
//  Created by Joseph McBride on 12/6/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa


class GameViewController : NSViewController {
    
    @IBOutlet weak var commandInput: NSTextField!
    @IBOutlet weak var accountInput: NSTextField!
    @IBOutlet weak var passwordInput: NSSecureTextField!
    @IBOutlet weak var characterInput: NSTextField!
    @IBOutlet var gameText: NSTextView!
    
    var authServer: AuthenticationServer?
    var gameServer: GameServer?
    var gameStream: GameStream?
    
    var presets: [String:String] = [
        "automapper": "#66FFFF",
        "chatter": "#66FFFF",
        "creatures": "#FFFF00",
        "roomdesc": "#cccccc",
        "roomname": "#0000FF",
        "scriptecho": "#66FFFF",
        "scripterror": "#efefef", // "#ff3300",
        "scriptinfo": "#0066cc",
        "scriptinput": "#acff2f",
        "sendinput": "#acff2f",
        "speech": "#66FFFF",
        "thought": "#66FFFF",
        "whisper": "#66FFFF",
        "exptracker": "#66FFFF"
    ]
    
    override func viewDidLoad() {
        
        accountInput.stringValue = ""
        characterInput.stringValue = ""
        
        authServer = AuthenticationServer()
        
        gameServer = GameServer({ [weak self] state in
            switch state {
            case .data(_, let str):
                print(str)
                self?.gameStream?.stream(str)
            case .closed:
                self?.gameStream?.resetSetup()
                self?.logText("Disconnected from game server")
            default:
                print("\(state)")
            }
        })
        
        gameStream = GameStream(context: GameContext(), streamCommands: {command in
            switch command {
            case .text(let tags):
                for tag in tags {
                    self.logTag(tag)
                }
            default:
                print(command)
            }
        })
    }

    @IBAction func Send(_ sender: Any) {
        let command = self.commandInput.stringValue
        
        if command.count == 0 { return }
        
        self.commandInput.stringValue = ""
        self.logText("\(command)\n")
        self.gameServer?.sendCommand(command)
    }
    
    @IBAction func Login(_ sender: Any) {

        let account = accountInput.stringValue
        let password = passwordInput.stringValue
        let character = characterInput.stringValue

        let authHost = "eaccess.play.net"
        let authPort:UInt16 = 7900

        self.logText("Connecting to authentication server at \(authHost):\(authPort) ...\n")

        self.authServer?.authenticate(
            AuthInfo(
                host: authHost,
                port: authPort,
                account: account,
                password: password,
                game: "DR",
                character: character),
            callback: { [weak self] result in

                switch result {
                case .success(let connection):
                    self?.logText("Connecting to game server at \(connection.host):\(connection.port) ...\n")
                    self?.gameServer?.connect(host: connection.host, port: connection.port, key: connection.key)

                default:
                    self?.logText("auth result: \(result)\n")
                }
            }
        )
    }
    
    func logTag(_ tag: TextTag) {
        
        if tag.window == "inv" {
            return
        }
        
        var foregroundColor = NSColor.white
        
        if tag.bold {
            foregroundColor = NSColor(hex: self.presets["creatures"]!)!
        }
        
        if let preset = tag.preset {
            if let value = self.presets[preset] {
                foregroundColor = NSColor(hex: value) ?? foregroundColor
            }
        }
        
        var font = NSFont(name: "Helvetica", size: 14)!
        
        if tag.mono {
            font = NSFont(name: "Menlo", size: 13)!
        }

        let  attributes:[NSAttributedString.Key:Any] = [
            NSAttributedString.Key.foregroundColor: foregroundColor,
            NSAttributedString.Key.font: font
        ]
        let str = NSAttributedString(string: tag.text, attributes: attributes)
        
        appendText(str)
    }
    
    func logText(_ text: String, window:String = "main") {
        let font = NSFont(name: "Helvetica", size: 14)!
        let  attributes = [
            NSAttributedString.Key.foregroundColor: NSColor.white,
            NSAttributedString.Key.font: font
        ]
        let str = NSAttributedString(string: text, attributes: attributes)
        
        appendText(str)
    }

    func appendText(_ text: NSAttributedString) {
        DispatchQueue.main.async {

            let smartScroll = self.gameText.visibleRect.maxY == self.gameText.bounds.maxY

            self.gameText.textStorage?.append(text)

            if smartScroll {
                self.gameText.scrollToEndOfDocument(self)
            }
        }
    }
}
