//
//  Coref.swift
//  TinodeSDK
//
//  Created by Wang Siman on 2/21/21.
//  Copyright © 2021 Tinode. All rights reserved.
//

import Foundation

public enum CorefError: LocalizedError {
    case notConnected(String)
    case serverResponseError(Int, String)
    case invalidState(String)
    
    public var description: String {
        get {
            switch self {
            case let .notConnected(msg):
                return "Not connected: \(msg)"
            case let .serverResponseError(code, text):
                return "Server response error http code: \(code), \(text)"
            case .invalidState(let message):
                return "Invalid state: \(message)"
            }
        }
    }
    public var errorDescription: String? {
        return description
    }
}

public protocol CorefEventListener: class {
    func onConnect(code: Int, reason: String)
    func onDisconnect(byServer: Bool, code: Int, reason: String)
    func onResolution(info: CorefResolution)
}


public class Coref {
    internal static let log = Log(subsystem: "co.tinode.tinodesdk")
    
    private class CorefConnectionListener: ConnectionListener {
        var coref: Coref
        var completionPromises : [PromisedReply<ServerMessage>] = []
        var promiseQueue = DispatchQueue(label: "co.coref.completion-promises")
        
        init(coref: Coref) {
            self.coref = coref
        }
        
        func onConnect(reconnecting: Bool, param: Any?) {
            let m = reconnecting ? "YES" : "NO"
            Coref.log.info("Coref connected: after reconnect - %@", m.description)
            coref.listenerNotifier.onConnect(code: 200, reason: "Coref connected")
        }
        
        func onMessage(with message: String) -> Void {
            // Do nothing
        }
        
        func onDisconnect(isServerOriginated: Bool, code: Int, reason: String) {
            let serverOriginatedString = isServerOriginated ? "YES" : "NO"
            Log.default.info("Coref disconnected: server originated [%@]; code [%d]; reason [%@]",
                             serverOriginatedString, code, reason)
            coref.handleDisconnect(isServerOriginated: isServerOriginated, code: code, reason: reason)
        }
        
        func onError(error: Error) {
            coref.handleDisconnect(isServerOriginated: true, code: 0, reason: error.localizedDescription)
            Log.default.error("Coref network error: %@", error.localizedDescription)
            try? rejectAllPromises(err: error)
        }
        
        func onResolution(with resolved: Data) -> Void {
            Log.default.debug("Received resolved data from coref server")
            do {
                try coref.process(resolved)
            } catch {
                Log.default.error("onResolution error: %@", error.localizedDescription)
            }
        }
        
        public func addPromise(promise: PromisedReply<ServerMessage>) {
            promiseQueue.sync {
                completionPromises.append(promise)
            }
        }
        
        private func completeAllPromises(msg: ServerMessage?, err: Error?) throws {
            let promises: [PromisedReply<ServerMessage>] = promiseQueue.sync {
                let promises = completionPromises.map { $0 }
                completionPromises.removeAll()
                return promises
            }
            if let e = err {
                try promises.forEach { try $0.reject(error: e) }
                return
            }
            if let msg = msg {
                try promises.forEach { try $0.resolve(result: msg) }
            }
        }
        private func resolveAllPromises(msg: ServerMessage?) throws {
            try completeAllPromises(msg: msg, err: nil)
        }
        private func rejectAllPromises(err: Error?) throws {
            try completeAllPromises(msg: nil, err: err)
        }
    }
    
    private class ListenerNotifier: CorefEventListener {
        private var listeners: [CorefEventListener] = []
        private var queue = DispatchQueue(label: "co.coref.listener")
        
        public func addListener(_ l: CorefEventListener) {
            queue.sync {
                guard listeners.firstIndex(where: { $0 === l }) == nil else { return }
                listeners.append(l)
            }
        }
        
        public func removeListener(_ l: CorefEventListener) {
            queue.sync {
                if let idx = listeners.firstIndex(where: { $0 === l }) {
                    listeners.remove(at: idx)
                }
            }
        }

        public var listenersThreadSafe: [CorefEventListener] {
            queue.sync { return self.listeners }
        }
        
        func onConnect(code: Int, reason: String) {
            listenersThreadSafe.forEach { $0.onConnect(code: code, reason: reason) }
        }

        func onDisconnect(byServer: Bool, code: Int, reason: String) {
            listenersThreadSafe.forEach { $0.onDisconnect(byServer: byServer, code: code, reason: reason) }
        }
        
        func onResolution(info: CorefResolution) {
            listenersThreadSafe.forEach { $0.onResolution(info: info) }
        }
    }
    
    public var useTLS: Bool
    public var hostName: String
    public var connection: Connection?
    public var isConnected: Bool {
        if let c = connection, c.isConnected {
            return true
        }
        return false
    }
    private var connectionListener: CorefConnectionListener? = nil
    private var listenerNotifier = ListenerNotifier()
    // Queue to execute state-mutating operations on.
    private let operationsQueue = DispatchQueue(label: "co.coref.operations")
    
    public static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .customRFC3339
        return encoder
    }()
    public static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .base64
        decoder.dateDecodingStrategy = .customRFC3339
        return decoder
    }()
    
    public init(fowardEventsTo l: CorefEventListener? = nil) {
        if let listener = l {
            self.listenerNotifier.addListener(listener)
        }
        self.useTLS = false
        self.hostName = ""
    }
    
    public init() {
        self.useTLS = false
        self.hostName = ""
    }
    
    public func addListener(_ l: CorefEventListener) {
        listenerNotifier.addListener(l)
    }
    public func removeListener(_ l: CorefEventListener) {
        listenerNotifier.removeListener(l)
    }
    
    private func buildURL(useWebsocketProtocol: Bool) -> URL? {
        guard !hostName.isEmpty else { return nil }
        let protocolString = useTLS ? (useWebsocketProtocol ? "wss://" : "https://") : (useWebsocketProtocol ? "ws://" : "http://")
        let urlString = "\(protocolString)\(hostName)/"
        return URL(string: urlString)
    }
    
    private func handleDisconnect(isServerOriginated: Bool, code: Int, reason: String) {
        let e = CorefError.notConnected("no longer connected to coref server")
        listenerNotifier.onDisconnect(byServer: isServerOriginated, code: code, reason: reason)
    }
    
    public func connect(to hostName: String, useTLS: Bool, inBackground bkg: Bool) throws -> PromisedReply<ServerMessage>? {
        try operationsQueue.sync {
            return try connectThreadUnsafe(to: hostName, useTLS: useTLS, inBackground: bkg)
        }
    }
    // Connect with saved connection params (host name and tls settings).
    @discardableResult
    private func connect(inBackground bkg: Bool) throws -> PromisedReply<ServerMessage>? {
        return try connectThreadUnsafe(to: self.hostName, useTLS: self.useTLS, inBackground: bkg)
    }
    
    private func connectThreadUnsafe(to hostName: String, useTLS: Bool, inBackground bkg: Bool) throws -> PromisedReply<ServerMessage>? {
        if isConnected {
            Coref.log.debug("Coref is already connected")
            return PromisedReply<ServerMessage>(value: ServerMessage())
        }
        self.useTLS = useTLS
        self.hostName = hostName
        guard let endpointURL = self.buildURL(useWebsocketProtocol: true) else {
            throw CorefError.invalidState("Could not form server url.")
        }

        if connection == nil {
            connectionListener = CorefConnectionListener(coref: self)
            connection = Connection(open: endpointURL,
                                    notify: connectionListener)
        }
        let connectedPromise = PromisedReply<ServerMessage>()
        connectionListener!.addPromise(promise: connectedPromise)
        try connection!.connect(withParam: bkg)
        return connectedPromise
    }
    
    public func reconnectNow(interactively: Bool, reset: Bool) -> Bool {
        operationsQueue.sync {
            var reconnectInteractive = interactively
            if connection == nil {
                do {
                    try connect(inBackground: false)
                    return true
                } catch {
                    Tinode.log.error("Couldn't connect to server: %@", error.localizedDescription)
                    return false
                }
            }
            if connection!.isConnected {
                // We are done unless we need to reset the connection.
                if !reset {
                    return true
                }
                connection!.disconnect()
                reconnectInteractive = true
            }

            // Connection exists but not connected.
            // Try to connect immediately only if requested or if
            // autoreconnect is not enabled.
            if reconnectInteractive || !connection!.isWaitingToConnect {
                do {
                    try connection!.connect(reconnectAutomatically: true, withParam: nil)
                    return true
                } catch {
                    return false
                }
            }
            return false
        }
    }
    
    public func disconnect() {
        operationsQueue.sync {
            connection?.disconnect()
        }
    }
    
    public func request(text: String, context: String?) -> PromisedReply<ServerMessage> {
        var input: String
        if let _context = context {
            input = _context + " " + text
        } else {
            input = text
        }
        return sendWithPromise(input: input)
    }
    
    private func send(payload: String) throws {
        guard let conn = connection else {
            throw CorefError.notConnected("Attempted to send data to a closed connection with coref server")
        }
        let jsonData = try Coref.jsonEncoder.encode(payload)
        Coref.log.debug("out: %@", String(decoding: jsonData, as: UTF8.self))
        conn.send(payload: jsonData)
    }
    
    private func sendWithPromise(input: String) -> PromisedReply<ServerMessage>{
        let future = PromisedReply<ServerMessage>()
        do {
            try send(payload: input)
        } catch {
            do {
                try future.reject(error: error)
            } catch {
                Coref.log.error("Error rejecting promise: %@", error.localizedDescription)
            }
        }
        return future
    }
    
    private func process(_ resolved: Data) throws {

        guard !resolved.isEmpty else {
            return
        }
        
        let corefResolution = try Coref.jsonDecoder.decode(CorefResolution.self, from: resolved)
        
        listenerNotifier.onResolution(info: corefResolution)
    }
}


