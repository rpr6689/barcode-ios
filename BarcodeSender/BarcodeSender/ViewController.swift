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
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var connection: NWConnection?
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
        requestScanner()
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
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func requestScanner() {
        DispatchQueue.main.async {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .authorized: // The user has previously granted access to the camera.
                    self.initializeScanner()
                
                case .notDetermined: // The user has not yet been asked for camera access.
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        if granted {
                            self.initializeScanner()
                        }
                    }
                
                case .denied: // The user has previously denied access.
                    return

                case .restricted: // The user can't grant access due to restrictions.
                    return
                @unknown default:
                    return
            }
        }
        
    }
    
    func initializeScanner() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.code128, .ean8, .ean13,]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(1103)
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        self.view.layer.sublayers = self.view.layer.sublayers?.filter { theLayer in
            !theLayer.isKind(of: AVCaptureVideoPreviewLayer.classForCoder())
        }
    }

    func found(code: String) {
        self.sendUDP(code)
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
}
