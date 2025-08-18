//
//  HomeView.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 14/08/2025.
//

import SwiftUI


struct HomeView:  View {
    @StateObject var cameraModel = QRScannerModel()
    
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                
                if let code = cameraModel.scannedCode {
                    Text(code)
                } else {
                    if !cameraModel.stopScanning {
                        Text("Scan a QR to begin!").font(.headline).foregroundStyle(.white)
                        CameraPreview(session: cameraModel.session).onAppear
                        {
                            cameraModel.checkPermissions()
                        }.padding([.top, .bottom], 140)
                            .padding([.leading, .trailing], 30)
                    } else {
                        DrawingCanvasView(viewModel: DrawingCanvasViewModel())
                    }
                }
            }
        }
        
        
    }
}
