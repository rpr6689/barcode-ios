//
//  ViewController.swift
//  BarcodeSender
//
//  Created by Casey Perkins on 7/12/22.
//

import UIKit
import Network
import AVFoundation

class ViewController: UIViewController {
    
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    
    var connection: NWConnection?
    //var hostUDP: NWEndpoint.Host = "localhost"
    var hostUDP: NWEndpoint.Host = "10.0.0.5"
    var portUDP: NWEndpoint.Port = 4445

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        var x = 0
        while(x < 1000000000) {
            x += 1
        }
    }

    
    @IBAction func onConnectClick(_ sender: Any) {
        //TODO: handle nfc, set host, then enable scanning
        connectToUDP(hostUDP, portUDP)
        self.connectButton.isEnabled = false
        self.scanButton.isEnabled = true
        self.disconnectButton.isEnabled = true
    }
    
    @IBAction func onScanClick(_ sender: Any) {
        //TODO: handle scan here
        
        //TODO: after scan
        //self.sendUDP(messageToUDP)
    }
    
    @IBAction func onDisconnectClick(_ sender: Any) {
        self.connectButton.isEnabled = true
        self.scanButton.isEnabled = false
        self.disconnectButton.isEnabled = false
        self.connection?.cancel()
    }
    
    func connectToUDP(_ hostUDP: NWEndpoint.Host, _ portUDP: NWEndpoint.Port) {

        self.connection = NWConnection(host: hostUDP, port: portUDP, using: .udp)

        self.connection?.stateUpdateHandler = { (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
                case .ready:
                    print("State: Ready\n")
                case .setup:
                    print("State: Setup\n")
                case .cancelled:
                    print("State: Cancelled\n")
                case .preparing:
                    print("State: Preparing\n")
                default:
                    print("ERROR! State not defined!\n")
            }
        }

        self.connection?.start(queue: .global())
    }

    func sendUDP(_ content: Data) {
        self.connection?.send(content: content, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }

    func sendUDP(_ content: String) {
        let contentToSendUDP = content.data(using: String.Encoding.utf8)
        self.connection?.send(content: contentToSendUDP, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if (NWError == nil) {
                print("Data was sent to UDP")
            } else {
                print("ERROR! Error when data (Type: Data) sending. NWError: \n \(NWError!)")
            }
        })))
    }

}

