//
//  DrawingCanvasViewModel.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 18/08/2025.
//

import SwiftUI

class DrawingCanvasViewModel: ObservableObject {
    
    @Published  var lines: [[CGPoint]] = []   // all lines drawn
    @Published  var currentLine: [CGPoint] = [] // points for the current line
    
    // Exposed coordinate of the current point
    @Published  var currentPoint: CGPoint? = nil

    var webSocketManager: WebSocketManager
    
    init(webSocketManager: WebSocketManager = globalWebsocketManager) {
        self.webSocketManager = webSocketManager
    }
    
    
    func sendCurrentPoint() {
        let data = try! JSONEncoder().encode(CanvasPointDTO(x: Double(currentPoint!.x), y: Double(currentPoint!.y)))
        webSocketManager.send(String(data: data, encoding: .utf8)!)
    }
    
}
