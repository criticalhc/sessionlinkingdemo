//
//  DrawingCanvasView.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 18/08/2025.
//


import SwiftUI

struct DrawingCanvasView: View {
 
    @ObservedObject var viewModel: DrawingCanvasViewModel
    
    var body: some View {
        VStack {
            ZStack {
                Color.white
                    .border(Color.gray)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let point = value.location
                                viewModel.currentLine.append(point)
                                viewModel.currentPoint = point
                                viewModel.sendCurrentPoint()
                            }
                            .onEnded { _ in
                                viewModel.lines.append(viewModel.currentLine)
                                viewModel.currentLine = []
                                viewModel.currentPoint = nil
                            }
                    )
                
                // Draw previous lines
                ForEach(viewModel.lines.indices, id: \.self) { i in
                    Path { path in
                        let line = viewModel.lines[i]
                        if let first = line.first {
                            path.move(to: first)
                            for point in line.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(Color.blue, lineWidth: 2)
                }
                
                // Draw current line
                Path { path in
                    if let first = viewModel.currentLine.first {
                        path.move(to: first)
                        for point in viewModel.currentLine.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(Color.red, lineWidth: 2)
            }
            .frame(width: 300, height: 400)
            
            if let point = viewModel.currentPoint {
                Text("Current point: x: \(Int(point.x)), y: \(Int(point.y))")
                    .padding()
            } else {
                Text("Drag to draw")
                    .padding()
            }
            
            Button("Clear") {
                viewModel.lines = []
                viewModel.currentLine = []
                viewModel.currentPoint = nil
            }
        }
    }
}
