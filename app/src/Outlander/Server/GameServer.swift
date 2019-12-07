//
//  GameServer.swift
//  Outlander
//
//  Created by Joseph McBride on 7/19/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation

enum GameServerState {
    case connected
    case data(Data, String)
    case closed(Error?)
}

class GameServer {
    var socket: Socket?
    var callback: ((GameServerState)-> Void)?
    var connection: String = ""
    var matchedToken = false

    init(_ callback: @escaping (GameServerState)->Void) {
        self.callback = callback
    }

    func connect(host: String, port: UInt16, key: String) {
        self.connection = "\(key)\r\n/FE:STORMFRONT /VERSION:1.0.26 /P:OSX /XML\r\n"

        self.socket = Socket({[weak self] state in
            switch state {
            case .connected:
                self?.callback?(.connected)
                if let connection = self?.connection {
                    self?.socket?.writeAndReadToNewline(connection)
                }

            case .data(let data, let str, _):
                if self?.matchedToken == false && str?.contains("GSw") == true {
                    self?.matchedToken = true

                    if let index = str!.index(of: "GSw") {
                        let substring = str![..<index]
                        self?.callback?(.data(data, String(substring)))
                    }

                    self?.socket?.write("\r\n")
                    self?.socket?.readToNewline()
                    return
                }

                self?.callback?(.data(data, str ?? ""))
                self?.socket?.readToNewline()

            case .closed(let error):
                self?.callback?(.closed(error))
                self?.matchedToken = false

            default:
                print("game sever: \(state)")
            }
        }, queue: DispatchQueue(label: "GameServer"))

        self.socket?.connect(host: host, port: port)
    }

    func disconnect() {
        self.socket?.disconnect()
        self.matchedToken = false
    }

    func sendCommand(_ command: String) {
        guard self.socket?.isConnected == true else {
            return
        }

        self.socket?.write("\(command)\r\n")
    }
}
