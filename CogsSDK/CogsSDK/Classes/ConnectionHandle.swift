
import Foundation
import Starscream

public class ConnectionHandle {
   
    private let defaultReconnectDelay: Double = 5
    
    private var webSocket : WebSocket
    private var options: PubSubOptions
    private var keys: [String]!
    private var sessionUUID: String?
    private var sequence: Int = 0
    
    public var onNewSession: ((String) -> ())?
    public var onReconnect: (() -> ())?
    public var onClose: ((Error?) -> ())?
    public var onError: ((Error) -> ())?
    public var onErrorResponse: ((PubSubErrorResponse) -> ())?
    public var onMessage: ((PubSubMessage) -> ())?
    public var onRawRecord: ((RawRecord) -> ())?
    
    public init(keys: [String], options: PubSubOptions) {
        
        self.keys    = keys
        self.options = options
        
        webSocket = WebSocket(url: URL(string: self.options.url)!)
        webSocket.timeout = self.options.connectionTimeout
        
        webSocket.onConnect = {
            self.getSessionUuid()
        }
        
        webSocket.onDisconnect = { (error: NSError?) in
            if let err = error, err.code != 1000 {
                self.onClose?(error)
            }

            self.onClose?(nil)

            if self.options.autoReconnect {
                Timer.scheduledTimer(timeInterval: self.defaultReconnectDelay, target: self, selector: #selector(self.reconnect(_:)), userInfo: nil, repeats: false)
            }
        }

        webSocket.onText = { (text: String) in
            self.onRawRecord?(text)
            
            DialectValidator.parseAndAutoValidate(record: text, completionHandler: { (json, error, responseError) in
                if let error = error {
                    self.onError?(error)
                } else if let respError = responseError {
                    self.onErrorResponse?(respError)
                } else if let j = json {
                    do {
                        let sessionUUID = try PubSubResponseUUID(json: j)

                        if sessionUUID.uuid == self.sessionUUID {
                            self.onReconnect?()
                            //self.onRawRecord?(text)
                        } else {
                            self.onNewSession?(sessionUUID.uuid)
                        }

                        self.sessionUUID = sessionUUID.uuid
                    } catch {
                        do {
                            let message = try PubSubMessage(json: j)
                            self.onMessage?(message)
                        } catch {
                            //self.onRawRecord?(text)
                        }
                    }
                }
            })
        }
    }
    
    /// Provides connection with the websocket
    ///
    /// - Parameters:
    ///   - keys: provided project keys in the following order [readKey, writeKey, adminKey]
    ///   - sessionUUID: when supplied client session will be restored if possible
    public func connect(sessionUUID: String?) {
        
        self.sessionUUID = sessionUUID
        
        let headers = SocketAuthentication.authenticate(keys: keys, sessionUUID: self.sessionUUID)
        
        webSocket.headers["Payload"] = headers.payloadBase64
        webSocket.headers["PayloadHMAC"] = headers.payloadHmac
        
        webSocket.connect()
    }
    
    ///  Disconnect from the websocket
    public func close() {
        if webSocket.isConnected {
            webSocket.disconnect()
        }
    }
    
    /// Getting session UUID
    public func getSessionUuid() {
        sequence += 1

        let params: [String: Any] = [
            "seq": sequence ,
            "action": "session-uuid"
        ]

        writeToSocket(params: params)
    }
    
    /// Subscribing to a channel
    ///
    /// - Parameter channelName: the name of the channel to subscribe
    public func subscribe(channelName: String) {
        sequence += 1

        let params: [String: Any] = [
            "seq": sequence,
            "action": "subscribe",
            "channel": channelName
        ]

        writeToSocket(params: params)
    }
    
    /// Unsubscribing from a channel
    ///
    /// - Parameter channelName: the name of the channel to unsubscribe from
    public func unsubsribe(channelName: String) {
        sequence += 1

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe",
            "channel": channelName
        ]

        writeToSocket(params: params)
    }
    
    /// Unsubscribing from all channels
    public func unsubscribeAll() {
        sequence += 1

        let params: [String: Any] = [
            "seq": sequence,
            "action": "unsubscribe-all"
        ]

        writeToSocket(params: params)
    }
    
    /// Gets all subscriptions
    public func listSubscriptions() {
        sequence += 1
        let params: [String: Any] = [
            "seq": sequence,
            "action": "subscriptions"
        ]

        writeToSocket(params: params)
    }
    
    /// Publishing a message to a channel
    ///
    /// - Parameters:
    ///   - channelName: the channel where message will be published
    ///   - message: the message to publish
    ///   - acknowledgement: acknowledgement for the published message
    public func publish(channelName: String, message: String, acknowledgement: Bool = false) {
        sequence += 1

        let params: [String: Any] = [
            "seq": sequence,
            "action": "pub",
            "chan": channelName,
            "msg": message,
            "ack": acknowledgement
        ]

        writeToSocket(params: params)
    }

    /// Publishing a message to a channel with acknowledgement
    ///
    /// - Parameters:
    ///   - channelName: the channel where message will be published
    ///   - message: the message to publish
    public func publishWithAck(channelName: String, message: String) {
        self.publish(channelName: channelName, message: message, acknowledgement: true)
    }
    
    private func writeToSocket(params: [String: Any]) {
        guard webSocket.isConnected else {
            self.onError?(NSError(domain: WebSocket.ErrorDomain, code: Int(100), userInfo: [NSLocalizedDescriptionKey: "Web socket is disconnected"]))
            //assertionFailure("Web socket is disconnected")
            return
        }
        
        do {
            let data: Data = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
            webSocket.write(data: data)
        } catch {
            self.onError?(error)
            //assertionFailure(error.localizedDescription)
        }
    }
    
    @objc private func reconnect(_ timer: Timer) {
        self.connect(sessionUUID: self.sessionUUID)
    }
}
