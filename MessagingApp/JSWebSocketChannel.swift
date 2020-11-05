//
//  JSWebSocketChannel.swift
//  MessagingApp
//
//  Created by Jinseon Kim on 2020/10/28.
//

import UIKit
import Starscream

class JSWebSocketChannel: NSObject {
    
    var socket: WebSocket?
    
    init(url: URL) {
        super.init()
        socket = WebSocket(request: URLRequest(url: url))
        socket?.delegate = self
        socket?.connect()
    }
    
}

extension JSWebSocketChannel: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        
    }
    
    
}
