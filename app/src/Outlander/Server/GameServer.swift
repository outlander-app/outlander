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
    var callback: ((GameServerState) -> Void)?
    var connection: String = ""
    var matchedToken = false

    var isConnected: Bool {
        socket?.isConnected ?? false
    }

    var log = LogManager.getLog(String(describing: GameServer.self))

    init(_ callback: @escaping (GameServerState) -> Void) {
        self.callback = callback
    }

    func connect(host: String, port: UInt16, key: String) {
        connection = "\(key)\r\n/FE:STORMFRONT /VERSION:1.0.26 /P:OSX /XML\r\n"

        socket = Socket({ [weak self] state in
            switch state {
            case .connected:
                self?.callback?(.connected)
                if let connection = self?.connection {
                    self?.socket?.writeAndReadToNewline(connection)
                }

            case let .data(data, str, _):
                if self?.matchedToken == false, str?.contains("GSw") == true {
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

            case let .closed(error):
                self?.matchedToken = false
                self?.callback?(.closed(error))

            default:
                self?.log.info("game sever: \(state)")
            }
        }, queue: DispatchQueue(label: "com.outlander:GameServer\(UUID().uuidString)", qos: .userInteractive))

        socket?.connect(host: host, port: port)
    }

    func disconnect() {
        socket?.disconnect()
        matchedToken = false
    }

    func sendCommand(_ command: String) {
        guard isConnected else {
            return
        }

        socket?.write("\(command)\r\n")
    }
}
