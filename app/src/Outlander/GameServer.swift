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
    case data(String)
    case closed(Error?)
}

class GameServer {
    var socket: Socket?
    var callback: ((GameServerState)-> Void)?
    var connection: String = ""
    
    init(_ callback: @escaping (GameServerState)->Void) {
        self.callback = callback
    }

    func connect(host: String, port: UInt16, key: String) {
        self.connection = "\(key)\r\n/FE:STORMFRONT /VERSION:1.0.26 /P:OSX /XML\r\n"
        
        self.socket = Socket({ state in
            switch state {
            case .connected:
                self.callback?(.connected)
                self.socket?.writeAndReadToNewline(self.connection)

            case .data(_, let str, _):
                self.callback?(.data(str ?? ""))
                self.socket?.readToNewline()

            case .closed(let error):
                self.callback?(.closed(error))

            default:
                print("game sever: \(state)")
            }
        }, queue: DispatchQueue.global(qos: .default))
        self.socket?.connect(host: host, port: port)
    }
    
    func disconnect() {
        self.socket?.disconnect()
    }

    func sendCommand(command: String) {
        guard self.socket?.isConnected == true else {
            return
        }

        self.socket?.write("\(command)\r\n")
    }
}
