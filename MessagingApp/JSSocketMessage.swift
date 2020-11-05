//
//  JSSocketMessage.swift
//  MessagingApp
//
//  Created by Jinseon Kim on 2020/10/30.
//

import UIKit

class JSSocketMessageData: Codable {
    var sdp: String
    var sdpMLineIndex: Int32?
    var sdpMid: String?
    
    init(sdp: String, sdpMLineIndex: Int32?, sdpMid: String?) {
        self.sdp = sdp
        self.sdpMLineIndex = sdpMLineIndex
        self.sdpMid = sdpMid
    }
}

class JSSocketMessage: Codable {
    
    var event: String
    var data: JSSocketMessageData

    init(event: String, data: JSSocketMessageData) {
        self.event = event
        self.data = data
    }
}
