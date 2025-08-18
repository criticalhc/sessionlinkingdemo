//
//  WebSocketManager.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 18/08/2025.
//


import Foundation
import Combine

class WebSocketManager: ObservableObject {
    @Published var messages: [String] = []   // history of received messages
    @Published var isConnected = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var url: URL?
    
    
    func connect(url: URL) {
        self.url = url
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        listen()
    }
    
    func send(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.messages.append("❌ Send error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.messages.append("❌ Receive error: \(error.localizedDescription)")
                    self?.isConnected = false
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.messages.append("📩 \(text)")
                    }
                case .data(let data):
                    DispatchQueue.main.async {
                        self?.messages.append("📩 Binary (\(data.count) bytes)")
                    }
                @unknown default:
                    break
                }
                // keep listening
                self?.listen()
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }
}
