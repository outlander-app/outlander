//
//  Socket.swift
//  Outlander
//
//  Created by Joseph McBride on 7/19/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import CocoaAsyncSocket
import Foundation

extension GCDAsyncSocket {
    func write(_ string: String, tag: Int) {
        let data = string.data(using: .utf8)
        write(data!, withTimeout: -1, tag: tag)
    }
}

enum SocketState {
    case initialized
    case connecting(String, UInt16)
    case connected
    case data(Data, String?, Int)
    case closed(Error?)
}

class Socket: NSObject, GCDAsyncSocketDelegate {
    private var _socket: GCDAsyncSocket?
    private var _callback: (SocketState) -> Void

    init(_ callback: @escaping (SocketState) -> Void, queue: DispatchQueue) {
        _callback = callback
        super.init()

        _socket = GCDAsyncSocket(delegate: self, delegateQueue: queue)
        _callback(.initialized)
    }

    public var useTLS: Bool = false

    public var isConnected: Bool { _socket?.isConnected ?? false }

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

    public func writeAndReadToNewline(_ data: String, tag: Int = -1) {
        _socket?.write(data, tag: tag)
        readToNewline()
    }

    public func readToNewline(tag: Int = -1) {
        _socket?.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: tag)
    }

    public func write(_ data: String) {
        _socket?.write(data, tag: -1)
    }

    @objc func socketDidSecure(_: GCDAsyncSocket) {
//        print("socketDidSecure \(sock.isSecure)")
    }

    @objc func socket(_: GCDAsyncSocket, didReceive _: SecTrust, completionHandler: @escaping (Bool) -> Void) {
//        print("socket did receive trust \(trust)")
        completionHandler(true)
    }

    @objc func socket(_: GCDAsyncSocket, didConnectToHost _: String, port _: UInt16) {
        if useTLS {
//            print("starting TLS")
            var settings: [String: NSObject] = [:]
            settings[GCDAsyncSocketManuallyEvaluateTrust as String] = Int(truncating: true) as NSNumber
            _socket?.startTLS(settings)
        }

        _callback(.connected)
    }

    @objc func socket(_: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let str = String(data: data, encoding: .utf8)
        _callback(.data(data, str, tag))
    }

    @objc func socketDidDisconnect(_: GCDAsyncSocket, withError err: Error?) {
        _callback(.closed(err))
    }
}
