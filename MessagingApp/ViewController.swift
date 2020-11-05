//
//  ViewController.swift
//  MessagingApp
//
//  Created by Jinseon Kim on 2020/10/27.
//

import UIKit
import WebRTC

class ChatViewController: UIViewController {

    // UI properties.
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    
    // Data properties.
    var messages: [String] = []
    
    // WebRTC properties.
    var peerConnection: RTCPeerConnection?
    var dataChannel: RTCDataChannel?
    var isInitiator: Bool = true
    
    let defaultOfferConstraints: RTCMediaConstraints = {
        let mandatoryConstraints:[String:String] = [
            kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueFalse,
            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueFalse,
        ]
        let cons = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        return cons
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        
        createOffer()
        createChannel()
    }
    
    @IBAction func send(_ sender: Any) {
        guard let text = textField.text else {return}
        if text.count > 0 {
            if let data = text.data(using: .utf8) {
                dataChannel?.sendData(RTCDataBuffer(data: data, isBinary: true))
                messages.append(text)
                textField.text = ""
                tableView.reloadData()
            }
        }
    }
    
    private func createOffer() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement":"true"])
        let factory = RTCPeerConnectionFactory()
        let server = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        let config = RTCConfiguration()
        config.iceServers = [server]
        config.iceTransportPolicy = .all
        config.rtcpMuxPolicy = .negotiate
        config.continualGatheringPolicy = .gatherContinually
        config.bundlePolicy = .balanced
        config.sdpSemantics = .unifiedPlan
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
        peerConnection?.delegate = self
        peerConnection?.offer(for: defaultOfferConstraints, completionHandler: { (sdp, error) in
            guard let sdp = sdp else {return}
            self.peerConnection(self.peerConnection!, didCreateSessionDescription: sdp, error: error)
        })
    }
    
    private func createChannel() {
        let config = RTCDataChannelConfiguration()
        config.isNegotiated = false
        config.isOrdered = false
        dataChannel = peerConnection?.dataChannel(forLabel: "JSChannel", configuration: config)
        dataChannel?.delegate = self
    }
    
    func sendSignalingMessage(sdp: RTCSessionDescription) {
        let type = sdp.type.rawValue
        let json = ["type": type, "sdp": sdp] as [String : Any]
        var jsonData:Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        } catch let error {
            fatalError(error.localizedDescription)
        }
        if jsonData != nil {
            
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didCreateSessionDescription sdp: RTCSessionDescription, error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                return
            }
            self.peerConnection?.setLocalDescription(sdp) { (error) in
                self.peerConnection(self.peerConnection!, didSetSessionDescriptionWithError: error)
            }
            
            
            
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didSetSessionDescriptionWithError error: Error?) {
        DispatchQueue.main.async {
            if error != nil {
                return
            }
            if self.peerConnection?.localDescription == nil {
                self.peerConnection?.answer(for: self.defaultOfferConstraints, completionHandler: { (sdp, error) in
                    self.peerConnection(self.peerConnection!, didCreateSessionDescription: sdp!, error: error)
                })
            }
        }
    }
}

extension ChatViewController: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        
    }
}

extension ChatViewController: RTCPeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
    
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") else {return UITableViewCell()}
        cell.textLabel?.text = messages[indexPath.row]
        return cell
    }
}
