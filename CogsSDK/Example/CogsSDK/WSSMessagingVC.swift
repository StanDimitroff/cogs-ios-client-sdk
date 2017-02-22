
import Foundation
import CogsSDK

class WSSMessagingVC: ViewController {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var sessionUUIDLabel: UILabel!
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var channelListLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageChannelTextField: UITextField!
    @IBOutlet weak var ackSwitch: UISwitch!
    @IBOutlet weak var receivedMessageLabel: UILabel!
    @IBOutlet weak var acknowledgeLabel: UILabel!

    fileprivate var pubSubService = CogsPubSubService(options: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        pubSubService.onNewSession = {
            DispatchQueue.main.async {
                self.statusLabel.text = "New session is opened"
            }
        }

        pubSubService.onReconnect = {
            DispatchQueue.main.async {
                self.statusLabel.text = "Session is restored"
            }
        }

        pubSubService.onDisconnect = {
            DispatchQueue.main.async {
                self.statusLabel.text = "Service is disconnected"
            }
        }
    }

    @IBAction func connectWS(_ sender: UIBarButtonItem) {
        let keys: [String] = [
            "R-6481112d4758dc51c59360ca7124742b-8ee36ea80f02ff9762f9b4dc62e79e5c8c5e23c11acd9beccad99fee10bfb690",
            "W-6481112d4758dc51c59360ca7124742b-e15d6a5a1bd755b5a37abcb6f10230e44bf08a05196881b70adf28112f80dc83",
            "A-6481112d4758dc51c59360ca7124742b-6f00499e82c694d97d3096f37ed63e136f86170c99ce736a869558806f8e42f42e4b158a4093ead428bb36b36dbff1623f7ca784e079c3783382333b5db58e51"
        ]

        pubSubService.connect(keys: keys, sessionUUID: nil)
    }

    @IBAction func disconnectWS(_ sender: UIBarButtonItem) {
        pubSubService.close()
    }

    @IBAction func getSessionUUID(_ sender: UIButton) {
        pubSubService.getSessionUuid() { json in
            do {
                let id = try PubSubResponseUUID(json: json)
                DispatchQueue.main.async {
                    self.sessionUUIDLabel.text = id.uuid
                }
            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func subscribeToChannel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }

        pubSubService.subscribe(channelName: channelName) { json in

            do {
                let subscription = try PubSubResponseSubscription(json: json)
                DispatchQueue.main.async {
                    self.channelListLabel.text = subscription.channels.joined(separator: "\n")
                }
            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func unsubscribeFromCahnnel(_ sender: UIButton) {
        guard let channelName = channelNameTextField.text, !channelName.isEmpty else { return }

        pubSubService.unsubsribe(channelName: channelName) { json in
            do {
                let subscription = try PubSubResponseSubscription(json: json)
                DispatchQueue.main.async {
                    self.channelListLabel.text = subscription.channels.joined(separator: "\n")
                }
            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func getAllSubscriptions(_ sender: UIButton) {
        pubSubService.listSubscriptions { json in
            do {
                let subscription = try PubSubResponseSubscription(json: json)
                DispatchQueue.main.async {
                    self.channelListLabel.text = subscription.channels.joined(separator: "\n")
                }
            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func unsubscribeFromAll(_ sender: UIButton) {
        pubSubService.unsubscribeAll{ json in
            do {
                let subscription = try PubSubResponseSubscription(json: json)
                DispatchQueue.main.async {
                    self.channelListLabel.text = subscription.channels.joined(separator: "\n")
                }

            } catch {
                do {
                    let responseError = try PubSubErrorResponse(json: json)
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.openAlertWithMessage(message: "\(error)", title: "Error")
                    }
                }
            }
        }
    }

    @IBAction func publishMessage(_ sender: UIButton) {
        guard let channel = channelNameTextField.text, !channel.isEmpty else { return }
        let messageText = messageTextView.text!
        let ack = ackSwitch.isOn

        if ack {
            pubSubService.publishWithAck(channelName: channel, message: messageText) { json in
                do {
                    let receivedMessage = try PubSubMessage(json: json)
                    DispatchQueue.main.async {
                        self.receivedMessageLabel.text = receivedMessage.message
                    }
                } catch {
                    do {
                        let acknowledge = try PubSubResponse(json: json)
                        DispatchQueue.main.async {
                            self.acknowledgeLabel.text = "\(acknowledge.description)"
                        }
                    } catch {
                        do {
                            let responseError = try PubSubErrorResponse(json: json)
                            DispatchQueue.main.async {
                                self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.openAlertWithMessage(message: "\(error)", title: "Error")
                            }
                        }
                    }
                }
            }
        } else {
            pubSubService.publish(channelName: channel, message: messageText) { json in
                do {
                    let receivedMessage = try PubSubMessage(json: json)
                    DispatchQueue.main.async {
                        self.receivedMessageLabel.text = receivedMessage.message
                    }
                } catch {
                    do {
                        let responseError = try PubSubErrorResponse(json: json)
                        DispatchQueue.main.async {
                            self.openAlertWithMessage(message: responseError.message, title: responseError.message)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.openAlertWithMessage(message: "\(error)", title: "Error")
                        }
                    }
                }
            }
        }
    }

    fileprivate func openAlertWithMessage(message msg: String, title: String) {
        let actionCtrl = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        actionCtrl.addAction(action)

        self.present(actionCtrl, animated: true, completion: nil)
    }
}
