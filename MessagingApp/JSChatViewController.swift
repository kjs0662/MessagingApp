//
//  ChatViewController.swift
//  MessagingApp
//
//  Created by Jinseon Kim on 2020/10/27.
//

import UIKit
import WebRTC
import Starscream

class JSChatViewController: UIViewController {
    
    // UI properties.
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    
    // Data properties.
    private var messages: [String] = []
    internal var isCaller: Bool = true
    
    // WebRTC properties.
    private var peerConnection: RTCPeerConnection!
    private var dataChannel: RTCDataChannel!
    
    // Socket properties.
    private var socket: WebSocket!
    
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
        if isCaller {
            let offerButton = UIBarButtonItem(title: "offer", style: .plain, target: self, action: #selector(createOffer))
            navigationItem.rightBarButtonItem = offerButton
        }
        sendButton.isEnabled = false
        
        var request = URLRequest(url: URL(string: "ws://localhost:8080/socket")!)
        request.timeoutInterval = 30
        socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
        createPeerConnection()
        createChannel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        socket.disconnect()
        super.viewWillDisappear(animated)
    }
    
    private func createPeerConnection() {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement":"true"])
        let factory = RTCPeerConnectionFactory()
        let server = RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        let config = RTCConfiguration()
        config.iceServers = [server]
        config.sdpSemantics = .unifiedPlan
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
        peerConnection.delegate = self
    }
    
    @objc private func createOffer() {
        peerConnection.offer(for: defaultOfferConstraints, completionHandler: { (sdp, error) in
            guard let sdp = sdp else {return}
            DispatchQueue.main.async {
                self.peerConnection.setLocalDescription(sdp) { (error) in
                    let event = "offer"
                    self.sendSignalMessage(event: event, sdp: sdp)
                }
            }
        })
    }
    
    private func createChannel() {
        let config = RTCDataChannelConfiguration()
        config.isNegotiated = true
        config.isOrdered = true
        config.channelId = 1
        dataChannel = peerConnection.dataChannel(forLabel: "JSChannel", configuration: config)
        dataChannel.delegate = self
    }
    
    private func createAnswer() {
        peerConnection.answer(for: defaultOfferConstraints, completionHandler: { (sdp, error) in
            guard let sdp = sdp else {return}
            DispatchQueue.main.async {
                self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                    let event = "answer"
                    self.sendSignalMessage(event: event, sdp: sdp)
                })
            }
        })
    }
    
    private func sendSignalMessage(event: String, sdp: RTCSessionDescription) {
        let messageData = JSSocketMessageData(sdp: sdp.sdp, sdpMLineIndex: nil, sdpMid: nil)
        let message = JSSocketMessage(event: event, data: messageData)
        var jsonData:Data?
        do {
            jsonData = try JSONEncoder().encode(message)
        } catch let error {
            fatalError(error.localizedDescription)
        }
        if jsonData != nil {
            self.socket.write(data: jsonData!)
        }
    }
    
    private func setRemoteDescription(type: RTCSdpType, sdp: String) {
        let sdp = RTCSessionDescription(type: type, sdp: sdp)
        peerConnection.setRemoteDescription(sdp, completionHandler: { (error) in
            DispatchQueue.main.async {
                if !self.isCaller && self.peerConnection.localDescription == nil {
                    self.createAnswer()
                }
            }
        })
    }
    
    @IBAction func send(_ sender: Any) {
        guard let text = textField.text else {return}
        if text.count > 0 {
            if let data = text.data(using: .utf8) {
                let buffer = RTCDataBuffer(data: data, isBinary: false)
                let isSuccess = dataChannel.sendData(buffer)
                if isSuccess {
                    let txt = "Me: " + text
                    messages.append(txt)
                    textField.text = ""
                    tableView.reloadData()
                }
            }
        }
    }
}

extension JSChatViewController: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            print("websocket is connected: \(headers)")
            break
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
            break
        case .text(let string):
            print("Received text: \(string)")
            let messageString: String = string
            let messageData: Data = messageString.data(using: .utf8)!
            do {
                let jsonObj = try JSONDecoder().decode(JSSocketMessage.self, from: messageData)
                var type: RTCSdpType = .offer
                if jsonObj.event == "offer" {
                    type = .offer
                    setRemoteDescription(type: type, sdp: jsonObj.data.sdp)
                } else if jsonObj.event == "answer" {
                    type = .answer
                    setRemoteDescription(type: type, sdp: jsonObj.data.sdp)
                } else if jsonObj.event == "candidate"  {
                    let candidate = RTCIceCandidate(sdp: jsonObj.data.sdp, sdpMLineIndex: jsonObj.data.sdpMLineIndex!, sdpMid: jsonObj.data.sdpMid)
                    self.peerConnection.add(candidate)
                }
                
            } catch let error {
                fatalError(error.localizedDescription)
            }
            break
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viablityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            print("reboot server")
        case .error(_):
            socket.disconnect()
            break
        }
    }
}

extension JSChatViewController: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        DispatchQueue.main.async {
            switch dataChannel.readyState {
            case .connecting:
                self.title = "Connecting..."
                break
            case .open:
                self.title = "Connected!"
                self.sendButton.isEnabled = true
                break
            default:
                self.title = "???"
                break
            }
        }
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        let message = String(data: buffer.data, encoding: .utf8)
        guard let msg = message else {return}
        if msg.count > 0 {
            let text = "Someone: " + msg
            messages.append(text)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}

extension JSChatViewController: RTCPeerConnectionDelegate {
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
        DispatchQueue.main.async {
            let messageData = JSSocketMessageData(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid)
            let message = JSSocketMessage(event: "candidate", data: messageData)
            var jsonData:Data?
            do {
                jsonData = try JSONEncoder().encode(message)
            } catch let error {
                fatalError(error.localizedDescription)
            }
            if jsonData != nil {
                self.socket.write(data: jsonData!)
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        dataChannel.delegate = self
        self.dataChannel = dataChannel
    }
    
}

extension JSChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") else {return UITableViewCell()}
        cell.textLabel?.text = messages[indexPath.row]
        return cell
    }
}
