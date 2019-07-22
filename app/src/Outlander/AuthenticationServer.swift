//
//  AuthenticationServer.swift
//  Outlander
//
//  Created by Joseph McBride on 7/18/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

enum AuthSocketState : Int {
    case password       = 0
    case authenticate   = 1
    case game           = 2
    case characterlist  = 3
    case character      = 4
}

enum AuthenticationState {
    case connected
    case characters
    case success(GameConnectionInfo)
    case error(String)
    case closed
}

struct AuthInfo {
    var host: String
    var port: UInt16
    var account: String
    var password: String
    var game: String
    var character: String
}

struct GameConnectionInfo {
    var game: String
    var key: String
    var host: String
    var port: UInt16
}

class AuthenticationServer {

    var _socket: Socket?
    var _authInfo: AuthInfo?
    var _callback: ((AuthenticationState) -> Void)?

    init() {
    }

    public func authenticate(_ authInfo: AuthInfo, callback: @escaping ((AuthenticationState) -> Void)) {
        _authInfo = authInfo
        _callback = callback

        _socket = Socket({ [weak self] state in
            switch state {
            case .connected:
                self?._callback?(.connected)
                self?._socket?.writeAndRead("K\r\n", tag: AuthSocketState.password.rawValue)

            case .data(let data, let str, let tag):
                self?.handleData(data: data, str: str, state: AuthSocketState(rawValue: tag)!)

            case .closed(let error):
                if let error = error {
                    self?._callback?(.error(error.localizedDescription))
                }
                else { self?._callback?(.closed) }

            default:
                print("Auth Server socket state change \(state)")
            }
        })
        _socket?.connect(host: authInfo.host, port: authInfo.port)
    }

    func handleData(data: Data, str: String?, state: AuthSocketState) {
        print("state: \(state)")
        switch state {
        case .password:
            var request = "A\t\(_authInfo!.account)\t".data(using: .ascii, allowLossyConversion: true)!
            let hash = String(data: data, encoding: .ascii)!
            let passwordHash = self.encrypt(password: _authInfo!.password, with: hash)
            request.append(passwordHash!)
            let ending = "\r\n".data(using: .ascii, allowLossyConversion: true)!
            request.append(ending)
            _socket?.writeAndRead(request, tag: AuthSocketState.authenticate.rawValue)

        case .authenticate:
            guard let str = str else {
                self.disconnectWithError("unknown error")
                return
            }

            guard str.contains("KEY") else {
                var error = "did not recieve authorization key"
                
                if str.contains("PASSWORD") {
                    error = "invalid password"
                }
                if str.contains("NORECORD") {
                    error = "invalid account"
                }
                
                self.disconnectWithError(error)
                return
            }

            _socket?.writeAndRead("G\t\(_authInfo!.game)\r\n", tag: AuthSocketState.game.rawValue)
            
        case .game:
            _socket?.writeAndRead("C\r\n", tag: AuthSocketState.characterlist.rawValue)
            
        case .characterlist:
            
            print("socket data: \(str ?? "")")
            
            guard let str = str else {
                self.disconnectWithError("unable to get character list")
                return
            }

            let regex = try? Regex("(\\S_\\S[\\S0-9]+)\t\(_authInfo!.character)", options: [.caseInsensitive])

            guard let result = regex?.matches(str) else {
                self.disconnectWithError("unable to find character \(self._authInfo!.character)")
                return
            }

            let characterId = str[result[1]]
            print(characterId)
            _socket?.writeAndRead("L\t\(characterId)\tPLAY\r\n", tag: AuthSocketState.character.rawValue)
            
        case .character:
            print("socket data: \(str ?? "")")
            
            guard let str = str else {
                self.disconnectWithError("unable to get login key")
                return
            }

            let info = getConnection(str)
            _callback?(.success(info))
            _socket?.disconnect()
        }
    }

    func disconnectWithError(_ error: String) {
        _callback?(.error(error))
        _socket?.disconnect()
    }

    func encrypt(password: String, with hash: String) -> Data? {

        var arr: [NSNumber] = []

        let max = min(hash.count, password.count)

        for i in 0..<max {
            let h = hash[i].asciiValue!
            let p = password[i].asciiValue!

            let res = (h ^ (p - 32)) + 32

            arr.append(NSNumber(value: Int32(res)))
        }

        var hexHash = ""

        for num in arr {
            hexHash += String(format: "%X", num.intValue)
        }

        return Data(hexString: hexHash)
    }
    
    func getConnection(_ input: String) -> GameConnectionInfo {
        let game = getData(input, pattern: "GAMECODE=(\\S+)")
        let key = getData(input, pattern: "KEY=(\\w+)")
        let host = getData(input, pattern: "GAMEHOST=(\\S+)")
        let port = getData(input, pattern: "GAMEPORT=(\\d+)")
        let portNumber:UInt16 = UInt16(port)!
        return GameConnectionInfo(game: game, key: key, host: host, port: portNumber)
    }

    func getData(_ input: String, pattern: String) -> String {
        let range = try! Regex(pattern).matches(input)[1]
        return String(input[range])
    }
}
