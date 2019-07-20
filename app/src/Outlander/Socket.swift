//
//  Socket.swift
//  Outlander
//
//  Created by Joseph McBride on 7/19/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

extension GCDAsyncSocket {
    func write(_ string: String, tag: Int) {
        let data = string.data(using: .utf8)
        self.write(data!, withTimeout: -1, tag: tag)
    }
}

enum SocketState {
    case initialized
    case connecting(String, UInt16)
    case connected
    case data(Data, String?, Int)
    case closed(Error?)
}

class Socket : NSObject, GCDAsyncSocketDelegate {
    private var _socket: GCDAsyncSocket?
    private var _callback: (SocketState) -> Void

    init(_ callback: @escaping (SocketState) -> Void, queue: DispatchQueue = DispatchQueue.main) {
        _callback = callback
        super.init()

        _socket = GCDAsyncSocket(delegate: self, delegateQueue: queue)
        _callback(.initialized)
    }

    public var isConnected: Bool {
        get { return self._socket?.isConnected ?? false }
    }
    
    public func connect(host: String, port: UInt16) {
        _callback(.connecting(host, port))
        try? _socket?.connect(toHost: host, onPort: port)
    }

    public func disconnect() {
        _socket?.disconnectAfterReadingAndWriting()
    }
    
    public func writeAndRead(_ data: Data, tag: Int) {
        _socket?.write(data, withTimeout: -1, tag: -1)
        _socket?.readData(withTimeout: -1, tag: tag)
    }

    public func writeAndRead(_ data: String, tag: Int) {
        _socket?.write(data, tag: -1)
        _socket?.readData(withTimeout: -1, tag: tag)
    }
    
    public func writeAndReadToNewline(_ data: String) {
        _socket?.write(data, tag: -1)
        self.readToNewline()
    }

    public func readToNewline() {
        _socket?.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: -1)
    }

    public func write(_ data: String) {
        _socket?.write(data, tag: -1)
    }

    @objc func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        _callback(.connected)
    }

    @objc func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let str = String(data: data, encoding: .utf8)
        _callback(.data(data, str, tag))
    }
    
    @objc func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        _callback(.closed(err))
    }
}
