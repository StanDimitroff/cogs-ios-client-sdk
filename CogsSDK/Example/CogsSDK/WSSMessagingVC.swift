
import Foundation
import CogsSDK

class WSSMessagingVC: ViewController {

    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var readKeyTextField: UITextField!
    @IBOutlet weak var writeKeyTextField: UITextField!
    @IBOutlet weak var adminKeyTextField: UITextField!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sessionUUIDLabel: UILabel!
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var channelListLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageChannelTextField: UITextField!
    @IBOutlet weak var ackSwitch: UISwitch!
    @IBOutlet weak var receivedMessageLabel: UILabel!
    @IBOutlet weak var acknowledgeLabel: UILabel!

    fileprivate var fpubSubService: CogsPubSubService!
    fileprivate var connectionHandler: ConnectionHandle!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if DEBUG
        self.urlTextField.text = "wss://gamqa-api.aviatainc.com/pubsub"
        self.readKeyTextField.text = "R-6481112d4758dc51c59360ca7124742b-8ee36ea80f02ff9762f9b4dc62e79e5c8c5e23c11acd9beccad99fee10bfb690"
        self.writeKeyTextField.text = "W-6481112d4758dc51c59360ca7124742b-e15d6a5a1bd755b5a37abcb6f10230e44bf08a05196881b70adf28112f80dc83"
        self.adminKeyTextField.text = "A-6481112d4758dc51c59360ca7124742b-6f00499e82c694d97d3096f37ed63e136f86170c99ce736a869558806f8e42f42e4b158a4093ead428bb36b36dbff1623f7ca784e079c3783382333b5db58e51"
        #endif
    }

    @IBAction func connectWS(_ sender: UIBarButtonItem) {
        guard let url = urlTextField.text else { return }
        
        guard let readKey = readKeyTextField.text else { return }
        guard let writeKey = writeKeyTextField.text else { return }
        guard let adminKey = adminKeyTextField.text else { return }
        
        let keys: [String] = [readKey, writeKey, adminKey]
        
        let pubSubService = CogsPubSubService()
        let connectionHandler = pubSubService.connnect(keys: keys,
                                                        options: PubSubOptions(url: url,
                                                                               timeout: 30,
                                                                               autoReconnect: true))
        self.connectionHandler = connectionHandler
        
        connectionHandler.onNewSession = { sessionUUID in
            DispatchQueue.main.async {
                self.statusLabel.text = "New session is opened"
                self.sessionUUIDLabel.text = sessionUUID
            }
        }

        connectionHandler.onReconnect = {
            DispatchQueue.main.async {
                self.statusLabel.text = "Session is restored"
            }
        }

        connectionHandler.onClose = { (error) in
            if let err = error {
                DispatchQueue.main.async {
                    self.openAlertWithMessage(message: err.localizedDescription, title: "PubSub Error")
                }
            } else {
                DispatchQueue.main.async {
                    self.statusLabel.text = "Session is closed"
                }
            }
        }

        connectionHandler.onRawRecord = { (record) in
            print (record)
            do {
                 let json = try JSONSerialization.jsonObject(with: record.data(using: String.Encoding.utf8)!, options: .allowFragments) as JSON

                do {
                    let sessionUUID = try PubSubResponseUUID(json: json)

                    DispatchQueue.main.async {
                        self.sessionUUIDLabel.text = sessionUUID.uuid
                    }
                } catch {
                    do {
                        let subscription = try PubSubResponseSubscription(json: json)

                        DispatchQueue.main.async {
                            self.channelListLabel.text = subscription.channels.joined(separator: ", ")
                        }
                    } catch {
                        let error = NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])
                        DispatchQueue.main.async {
                            self.openAlertWithMessage(message: error.localizedDescription, title: "PubSub Error")
                        }
                    }
                }
            } catch {
                let error = NSError(domain: "CogsSDKError - PubSub Response", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad JSON"])

                DispatchQueue.main.async {
                    self.openAlertWithMessage(message: error.localizedDescription, title: "PubSub Error")
                }
            }
        }

        connectionHandler.onMessage = { (receivedMessage) in
            DispatchQueue.main.async {
                self.receivedMessageLabel.text = receivedMessage.message
            }
        }

        connectionHandler.onError = { (error) in
            DispatchQueue.main.async {
                self.openAlertWithMessage(message: error.localizedDescription, title: "PubSub Error")
            }
        }

        connectionHandler.onErrorResponse = { (responseError) in
            DispatchQueue.main.async {
                self.openAlertWithMessage(message: responseError.message, title: "PubSub Response Error")
            }
        }
        
        connectionHandler.connect(sessionUUID: nil)
    }

    @IBAction func disconnectWS(_ sender: UIBarButtonItem) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.close()
    }

    @IBAction func getSessionUUID(_ sender: UIButton) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.getSessionUuid()
    }

    @IBAction func subscribeToChannel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard (connectionHandler) != nil else { return }

        connectionHandler.subscribe(channelName: channelName)
    }

    @IBAction func unsubscribeFromCahnnel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }
        guard (connectionHandler) != nil else { return }

        connectionHandler.unsubsribe(channelName: channelName)
    }

    @IBAction func getAllSubscriptions(_ sender: UIButton) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.listSubscriptions()
    }

    @IBAction func unsubscribeFromAll(_ sender: UIButton) {
        guard (connectionHandler) != nil else { return }

        connectionHandler.unsubscribeAll()
    }

    @IBAction func publishMessage(_ sender: UIButton) {
        guard let channel = channelNameTextField.text, !channel.isEmpty else { return }
        let messageText = messageTextView.text!
        let ack = ackSwitch.isOn

        guard (connectionHandler) != nil else { return }

        if ack {
            connectionHandler.publishWithAck(channelName: channel, message: messageText)
        } else {
            connectionHandler.publish(channelName: channel, message: messageText)
        }
    }

    fileprivate func openAlertWithMessage(message msg: String, title: String) {
        let actionCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        actionCtrl.addAction(action)

        self.present(actionCtrl, animated: true, completion: nil)
    }
}
