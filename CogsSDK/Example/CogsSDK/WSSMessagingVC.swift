
import Foundation
import CogsSDK

class WSSMessagingVC: ViewController {
    
    @IBOutlet weak var statusLabel: UILabel!

    @IBAction func connectWS(_ sender: UIBarButtonItem) {
        let keys: [String] = [
            "R-6481112d4758dc51c59360ca7124742b-8ee36ea80f02ff9762f9b4dc62e79e5c8c5e23c11acd9beccad99fee10bfb690",
            "W-6481112d4758dc51c59360ca7124742b-e15d6a5a1bd755b5a37abcb6f10230e44bf08a05196881b70adf28112f80dc83",
            "A-6481112d4758dc51c59360ca7124742b-6f00499e82c694d97d3096f37ed63e136f86170c99ce736a869558806f8e42f42e4b158a4093ead428bb36b36dbff1623f7ca784e079c3783382333b5db58e51"
        ]

        CogsPubSubService.sharedService.connect(keys: keys)
    }

    @IBAction func disconnectWS(_ sender: UIBarButtonItem) {
        CogsPubSubService.sharedService.disconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        CogsPubSubService.sharedService.delegate = self
    }
}

extension WSSMessagingVC: CogsPubSubServiceDelegate {
    func socketDidConnect() {
        statusLabel.text = "Socket connected"
    }

    func socketDidDisconnect() {
        statusLabel.text = "Socket disconnected"
    }
}
